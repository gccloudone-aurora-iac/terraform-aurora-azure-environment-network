locals {
  prefix = "dev"
  azure_tags = {
    DataClassification      = "Undefined"
    wid                     = 000001
    Metadata                = "Undefined"
    environment             = "dev"
    PrimaryTechnicalContact = "william.hearn@ssc-spc.gc.ca"
    PrimaryProjectContact   = "albertabdullah.kouri@ssc-spc.gc.ca"
  }
}

#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

# Manages an Azure Resource Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "Canada Central"
}

# Manages an Azure Network Security Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_network_security_group" "this" {
  name                = "${local.prefix}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  security_rule       = []

  tags = local.azure_tags
}

# Manages an Azure Route Table. The route table redirects traffic heading to the internet to the firewall first.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_route_table" "this" {
  name                = "${local.prefix}-rt"
  resource_group_name = azurerm_resource_group.example.name
  location            = "Canada Central"

  route = [
    {
      name                   = "${local.prefix}-route-default"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "172.23.160.22"
    }
  ]

  tags = local.azure_tags
}

# Remote virtual network

resource "azurerm_resource_group" "remote" {
  name     = "example-remote-vnet-rg"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "remote" {
  name                = "example-remote-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = "Canada Central"
  resource_group_name = azurerm_resource_group.example.name
}

##############################
### Virtual Network Module ###
##############################

# Manages the Cloud Native Platform network resources.
#
# https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-environment-network
#
module "network" {
  source = "../"

  naming_convention = "gc"
  user_defined      = "example"

  azure_resource_attributes = {
    department_code = "Gc"
    owner           = "ABC"
    project         = "aur"
    environment     = "dev"
    location        = azurerm_resource_group.example.location
    instance        = 0
  }

  vnet_address_space = ["10.0.0.0/21"]
  vnet_peers         = [azurerm_virtual_network.remote.id]

  subnets = {
    RouteServerSubnet = {
      address_prefixes      = ["10.0.0.0/27"]
      create_nsg            = false
      associate_route_table = false
    }
    apiserver = {
      address_prefixes = ["10.0.0.32/27"]
    }
    loadbalancer = {
      address_prefixes = ["10.0.0.64/27"]
    }
    gateway = {
      address_prefixes = ["10.0.0.96/27"]
    }
    infrastructure = {
      address_prefixes = ["10.0.0.128/27"]
      nsg_id           = azurerm_network_security_group.this.id
      route_table_id   = azurerm_route_table.this.id
      extra_nsg_rules = [
        {
          name                         = "test"
          description                  = "test"
          priority                     = 103
          direction                    = "Outbound"
          access                       = "Allow"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = ["1.1.1.1"]
          destination_address_prefixes = ["1.1.1.2"]
        }
      ]
    }
    system = {
      address_prefixes = ["10.0.0.160/27"]
    }
    general = {
      address_prefixes  = ["10.0.1.0/25"]
      service_endpoints = ["Microsoft.Storage"]
      service_endpoint_policy_definitions = [{
        scopes = [azurerm_resource_group.example.id]
      }]
    }
  }

  route_server_bgp_peers = [
    {
      name     = "${local.prefix}-vm-router"
      peer_asn = "64512"
      peer_ip  = "172.26.25.36"
    },
    {
      name     = "hello-vm-router"
      peer_asn = "64512"
      peer_ip  = "172.26.25.37"
    }
  ]

  route_table_next_hop_ip_address = ""

  tags = local.azure_tags
}
