######################
### Resource Group ###
######################

output "resource_group_id" {
  description = "The id of the resource group created."
  value       = azurerm_resource_group.network.id
}

output "resource_group_name" {
  description = "The name of the resource group created."
  value       = azurerm_resource_group.network.name
}

##############################
### Network Security Group ###
##############################

output "nsg_ids" {
  description = "The resource ids of the network security groups created within this module."
  value       = { for k, value in azurerm_network_security_group.this : k => value.id }
}

####################
### Route Tables ###
####################

output "route_table_id" {
  description = "The address space of the newly created virtual network"
  value       = azurerm_route_table.this.id
}

output "route_table_subnets" {
  description = "The address space of the newly created virtual network"
  value       = azurerm_route_table.this.subnets
}

#######################
### Virtual Network ###
#######################

output "vnet_address_space" {
  description = "The address space of the newly created virtual network"
  value       = module.virtual_network.address_space
}

output "vnet_id" {
  description = "The id of the newly created virtual network"
  value       = module.virtual_network.id
}

output "vnet_location" {
  description = "The location of the newly created virtual network"
  value       = module.virtual_network.location
}

output "vnet_name" {
  description = "The Name of the newly created virtual network"
  value       = module.virtual_network.name
}

output "vnet_subnets" {
  description = "The ids of subnets created inside the newly created virtual network"
  value       = module.virtual_network.vnet_subnets
}

output "vnet_subnets_name_id" {
  description = "Can be queried subnet-id by subnet name by using lookup(module.vnet.vnet_subnets_name_id, subnet1)"
  value       = module.virtual_network.vnet_subnets_name_id
}

####################
### Route Server ###
####################

output "route_server_public_ip_id" {
  description = "The id of the public IP used by the route server"
  value       = module.route_server.public_ip_id
}

output "route_server_public_ip_address" {
  description = "The IP address of the public IP used by the route server"
  value       = module.route_server.public_ip_address
}

output "route_server_id" {
  description = "The ID of the Route Server."
  value       = module.route_server.id
}

output "route_server_ip_addresses" {
  description = "The peer IP addresses of the Route Server. In other words, it is the private IPs of the route server."
  value       = module.route_server.route_server_ip_addresses
}

output "route_server_bgp_peers" {
  description = "The IDs of the Route Server BGP peers."
  value       = module.route_server.bgp_peers
}
