# terraform-aurora-azure-environment-network

This repository contains an opionionated Terraform module that can be used to create the networking Azure resources for the Cloud Native Platform. In summary, it does the following:

- creates a virtual network
- Creates subnets within the virtual network with an optional assoicated network security group & route table
- Creates a route server

The idea behind the module is to create and configure all the network resources that is shared amongst all of the Cloud Native Platform environments. module creates the following baseline subnets within the virtual network:

- loadbalancer
- route-server
- system
- general
- gateway

Each of these subnets will have a dedicated network security group and a shared route table that is associated to it. By default the network security group won't have any extra security rules, and the route table will only include a route that directs all traffic going to the internet, to hop to the firewall first. More rules can be added through the module's variables.

To add more subnets to virtual network (subnets that shouldn't be in any of the other environments), the var.extra_subnets variable can be used. Notice that if you want the extra subnet to have an assoicated network security group and route table, they will have to be created outside of this module.

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.26.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.26.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_resource_names"></a> [azure\_resource\_names](#module\_azure\_resource\_names) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-resource-names.git | v2.0.0 |
| <a name="module_route_server"></a> [route\_server](#module\_route\_server) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-route-server.git | v2.0.1 |
| <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network.git | v2.0.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_resource_attributes"></a> [azure\_resource\_attributes](#input\_azure\_resource\_attributes) | Attributes used to describe Azure resources | <pre>object({<br>    project     = string<br>    environment = string<br>    location    = optional(string, "Canada Central")<br>    instance    = number<br>  })</pre> | n/a | yes |
| <a name="input_route_server_bgp_peers"></a> [route\_server\_bgp\_peers](#input\_route\_server\_bgp\_peers) | The details for creating BGP peer(s) within the route server. | <pre>list(object({<br>    name     = string<br>    peer_asn = number<br>    peer_ip  = string<br>  }))</pre> | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The environment specific subnets to create in the virtual network. | <pre>map(object({<br>    address_prefixes = list(string)<br><br>    nsg_id     = optional(string)<br>    create_nsg = optional(bool, true)<br>    extra_nsg_rules = optional(list(object({<br>      name                                       = string<br>      description                                = string<br>      protocol                                   = string                 # Tcp, Udp, Icmp, Esp, Ah or *<br>      access                                     = string                 # Allow or Deny<br>      priority                                   = number                 # The value can be between 100 and 4096<br>      direction                                  = string                 # Inbound or Outbound<br>      source_port_range                          = optional(string)       # between 0 and 65535 or * to match any<br>      source_port_ranges                         = optional(list(string)) # required if source_port_range is not specified<br>      destination_port_range                     = optional(string)       # between 0 and 65535 or * to match any<br>      destination_port_ranges                    = optional(list(string)) # required if destination_port_range is not specified<br>      source_address_prefix                      = optional(string)<br>      source_address_prefixes                    = optional(list(string)) # required if source_address_prefix is not specified.<br>      source_application_security_group_ids      = optional(list(string))<br>      destination_address_prefix                 = optional(string)<br>      destination_address_prefixes               = optional(list(string)) #  required if destination_address_prefix is not specified<br>      destination_application_security_group_ids = optional(list(string))<br>    })), [])<br><br>    route_table_id        = optional(string)<br>    associate_route_table = optional(bool, true)<br><br>    service_endpoints                             = optional(list(string))<br>    service_delegation_name                       = optional(string)<br>    private_endpoint_network_policies_enabled     = optional(bool, true)<br>    private_link_service_network_policies_enabled = optional(bool, true)<br>  }))</pre> | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | The address space for the virtual network. | `list(string)` | n/a | yes |
| <a name="input_ddos_protection_plan_id"></a> [ddos\_protection\_plan\_id](#input\_ddos\_protection\_plan\_id) | The DDoS protection plan resource id | `string` | `null` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The IP addresses of the DNS servers to be used by the Azure virtual network. If no values specified, this defaults to Azure DNS. | `list(string)` | `[]` | no |
| <a name="input_extra_route_table_rules"></a> [extra\_route\_table\_rules](#input\_extra\_route\_table\_rules) | The environment specific security rules to add to the standard route table. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to assign to the resources | `map(string)` | `{}` | no |
| <a name="input_vnet_peers"></a> [vnet\_peers](#input\_vnet\_peers) | A list of remote virtual network resource IDs to use as virtual network peerings. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | The resource ids of the network security groups created within this module. |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | The id of the resource group created. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the resource group created. |
| <a name="output_route_server_bgp_peers"></a> [route\_server\_bgp\_peers](#output\_route\_server\_bgp\_peers) | The IDs of the Route Server BGP peers. |
| <a name="output_route_server_id"></a> [route\_server\_id](#output\_route\_server\_id) | The ID of the Route Server. |
| <a name="output_route_server_ip_addresses"></a> [route\_server\_ip\_addresses](#output\_route\_server\_ip\_addresses) | The peer IP addresses of the Route Server. In other words, it is the private IPs of the route server. |
| <a name="output_route_server_public_ip_address"></a> [route\_server\_public\_ip\_address](#output\_route\_server\_public\_ip\_address) | The IP address of the public IP used by the route server |
| <a name="output_route_server_public_ip_id"></a> [route\_server\_public\_ip\_id](#output\_route\_server\_public\_ip\_id) | The id of the public IP used by the route server |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | The address space of the newly created virtual network |
| <a name="output_route_table_subnets"></a> [route\_table\_subnets](#output\_route\_table\_subnets) | The address space of the newly created virtual network |
| <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space) | The address space of the newly created virtual network |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The id of the newly created virtual network |
| <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location) | The location of the newly created virtual network |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The Name of the newly created virtual network |
| <a name="output_vnet_subnets"></a> [vnet\_subnets](#output\_vnet\_subnets) | The ids of subnets created inside the newly created virtual network |
| <a name="output_vnet_subnets_name_id"></a> [vnet\_subnets\_name\_id](#output\_vnet\_subnets\_name\_id) | Can be queried subnet-id by subnet name by using lookup(module.vnet.vnet\_subnets\_name\_id, subnet1) |
<!-- END_TF_DOCS -->

## History

| Date       | Release | Change                                                                                                    |
| ---------- | ------- | --------------------------------------------------------------------------------------------------------- |
| 2025-01-25 | v1.0.0  | Initial commit                                                                                            |
| 2025-10-20 | v2.0.1  | Pin minimum version of azurerm to 4.49.0                                                                  |
