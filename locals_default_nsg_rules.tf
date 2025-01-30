// The unique security rules for each of the default AKS node pool NSGs
locals {
  default_node_pool_unique_nsg_rules = {
    gateway = {
      inbound = [
        {
          name                         = "deny-subnets-inbound"
          description                  = "Deny inbound flows from all subnets within the virtual network execpt from the gateway, apiserver, loadbalancer, system and general subnets."
          priority                     = 1000
          direction                    = "Inbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["loadbalancer", "system", "general", "gateway", "apiserver"], subnet_name)])
          destination_address_prefixes = var.subnets["gateway"].address_prefixes
        }
      ]
      outbound = [
        {
          name                         = "deny-subnets-outbound"
          description                  = "Deny outbound flows to all subnets within the virtual network except to the gateway, apiserver, system & general subnets."
          priority                     = 1000
          direction                    = "Outbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = var.subnets["gateway"].address_prefixes
          destination_address_prefixes = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["system", "general", "gateway", "apiserver"], subnet_name)])
        }
      ]
    }

    general = {
      inbound = [
        {
          name                         = "deny-subnets-inbound"
          description                  = "Deny inbound flows from all subnets within the virtual network execpt from the general, apiserver, gateway & system subnets."
          priority                     = 1000
          direction                    = "Inbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["gateway", "system", "general", "apiserver"], subnet_name)])
          destination_address_prefixes = var.subnets["general"].address_prefixes
        }
      ]
      outbound = [
        {
          name                         = "deny-subnets-outbound"
          description                  = "Deny outbound flows to all subnets within the virtual network except to the general, system, apiserver and gateway subnets."
          priority                     = 1000
          direction                    = "Outbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = var.subnets["general"].address_prefixes
          destination_address_prefixes = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["system", "general", "apiserver", "gateway"], subnet_name)])
        }
      ]
    }

    system = {
      inbound = [
        {
          name                         = "deny-subnets-inbound"
          description                  = "Deny inbound flows from all subnets within the virtual network execpt from the system, apiserver, gateway & system subnets."
          priority                     = 1000
          direction                    = "Inbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["gateway", "general", "system", "apiserver"], subnet_name)])
          destination_address_prefixes = var.subnets["system"].address_prefixes
        }
      ]
      outbound = [
        {
          name                         = "deny-subnets-outbound"
          description                  = "Deny outbound flows to all subnets within the virtual network except to the system, apiserver, gateway, general & infrastructure subnets."
          priority                     = 1000
          direction                    = "Outbound"
          access                       = "Deny"
          protocol                     = "*"
          source_port_range            = "*"
          destination_port_range       = "*"
          source_address_prefixes      = var.subnets["system"].address_prefixes
          destination_address_prefixes = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["gateway", "general", "infrastructure", "system", "apiserver"], subnet_name)])
        }
      ]
    }
  }
}

// The final NSG security rules used by each of the default NSGs
locals {
  default_nsg_rules = {
    loadbalancer = [
      {
        name                         = "deny-subnets-outbound"
        description                  = "Deny outbound flows to all subnets within the virtual network except to the gateway subnet."
        priority                     = 1000
        direction                    = "Outbound"
        access                       = "Deny"
        protocol                     = "*"
        source_port_range            = "*"
        destination_port_range       = "*"
        source_address_prefixes      = var.subnets["loadbalancer"].address_prefixes
        destination_address_prefixes = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["gateway"], subnet_name)])
      }
    ]

    apiserver = []

    gateway = concat(local.default_node_pool_unique_nsg_rules["gateway"].inbound, local.default_node_pool_unique_nsg_rules["gateway"].outbound)

    general = concat(local.default_node_pool_unique_nsg_rules["general"].inbound, local.default_node_pool_unique_nsg_rules["general"].outbound)

    system = concat(local.default_node_pool_unique_nsg_rules["system"].inbound, local.default_node_pool_unique_nsg_rules["system"].outbound)

    infrastructure = [
      {
        name                         = "deny-subnets-inbound"
        description                  = "Deny inbound flows from all subnets within the virtual network execpt from the system subnet."
        priority                     = 1000
        direction                    = "Inbound"
        access                       = "Deny"
        protocol                     = "*"
        source_port_range            = "*"
        destination_port_range       = "*"
        source_address_prefixes      = flatten([for subnet_name, value in var.subnets : value.address_prefixes if !contains(["system"], subnet_name)])
        destination_address_prefixes = var.subnets["infrastructure"].address_prefixes
      }
    ]
  }
}
