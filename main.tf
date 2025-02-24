# Manages an Azure Resource Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
#
resource "azurerm_resource_group" "network" {
  name     = "${module.azure_resource_prefixes.resource_group_prefix}-network"
  location = var.azure_resource_attributes.location

  tags = local.tags
}

###############################
### Network Security Groups ###
###############################

# Manages an Azure Network Security Group.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
#
resource "azurerm_network_security_group" "this" {
  for_each = local.nsg_security_rules

  name                = "${module.azure_resource_prefixes.network_security_group_prefix}-${each.key}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  dynamic "security_rule" {
    for_each = each.value.extra_nsg_rules
    content {
      name        = security_rule.value.name
      description = security_rule.value.description

      priority  = security_rule.value.priority
      direction = security_rule.value.direction
      access    = security_rule.value.access
      protocol  = security_rule.value.protocol

      source_port_range       = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges      = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range  = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges = lookup(security_rule.value, "destination_port_ranges", null)

      source_address_prefix        = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes      = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix   = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)

      source_application_security_group_ids      = lookup(security_rule.value, "source_application_security_group_ids", null)
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)
    }
  }

  tags = local.tags
}

####################
### Route Tables ###
####################

# Manages an Azure Route Table used by all the subnets within the Azure Virtual Network.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table
#
resource "azurerm_route_table" "this" {
  name                = module.azure_resource_prefixes.route_table_prefix
  resource_group_name = azurerm_resource_group.network.name
  location            = var.azure_resource_attributes.location

  route = concat([
    {
      name                   = "${module.azure_resource_prefixes.route_table_prefix}-default-route"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.route_table_next_hop_ip_address 
    }
  ], var.extra_route_table_rules)

  tags = local.tags
}

#######################
### Virtual Network ###
#######################

# Manages an Azure Virtual Network and the subnets within it.
#
# https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network
#
module "virtual_network" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network.git?ref=v1.0.0"

  azure_resource_attributes = var.azure_resource_attributes
  resource_group_name       = azurerm_resource_group.network.name

  address_space           = var.vnet_address_space
  vnet_peers              = var.vnet_peers
  dns_servers             = var.dns_servers
  ddos_protection_plan_id = var.ddos_protection_plan_id

  subnets             = local.subnets
  subnet_nsgs         = local.subnet_nsgs
  subnet_route_tables = local.subnet_route_tables

  tags = local.tags
}

####################
### Route Server ###
####################

# Manages an Azure Route Server and BGP connections within it.
#
# https://github.com/gccloudone-aurora-iac/terraform-azure-route-server
#
module "route_server" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-azure-route-server.git?ref=v1.0.0"

  azure_resource_attributes = var.azure_resource_attributes
  resource_group_name       = azurerm_resource_group.network.name
  subnet_id                 = lookup(module.virtual_network.vnet_subnets_name_id, "RouteServerSubnet")

  bgp_peers = var.route_server_bgp_peers

  tags = local.tags
}
