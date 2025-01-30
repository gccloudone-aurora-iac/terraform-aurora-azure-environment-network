locals {

  // All var.subnets elements that have create_nsg = true
  nsg_security_rules = {
    for subnet_name, value in var.subnets :
    subnet_name => {
      extra_nsg_rules = concat(value.extra_nsg_rules, lookup(local.default_nsg_rules, subnet_name, []))
    } if value.create_nsg != false
  }

  // The subnets to create in the vnet with the NSG & Route Tables assoications created within the module
  subnets = [
    for subnet_name, value in var.subnets :
    {
      name             = subnet_name
      address_prefixes = value.address_prefixes

      service_endpoints                   = value.service_endpoints
      service_endpoint_policy_definitions = value.service_endpoint_policy_definitions

      service_delegation_name                       = value.service_delegation_name
      private_endpoint_network_policies_enabled     = value.private_endpoint_network_policies_enabled
      private_link_service_network_policies_enabled = value.private_link_service_network_policies_enabled
    }
  ]

  // A list of subnets and their corresponding NSG to associate to them
  subnet_nsgs = [
    for subnet_name, value in var.subnets :
    {
      subnet_name = subnet_name
      nsg_id      = value.nsg_id != null ? value.nsg_id : azurerm_network_security_group.this[subnet_name].id
    } if value.create_nsg
  ]

  // A list of subnets and their corresponding route tables to associate to them
  subnet_route_tables = [
    for subnet_name, value in var.subnets :
    {
      subnet_name    = subnet_name
      route_table_id = value.route_table_id != null ? value.route_table_id : azurerm_route_table.this.id
    } if value.associate_route_table
  ]

  tags = merge(
    var.tags,
    {
      ModuleName    = "terraform-aurora-azure-environment-network",
      ModuleVersion = "v1.0.0",
    }
  )
}
