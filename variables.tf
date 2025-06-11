variable "azure_resource_attributes" {
  description = "Attributes used to describe Azure resources"
  type = object({
    department_code = string
    owner           = string
    project         = string
    environment     = string
    location        = optional(string, "Canada Central")
    instance        = number
  })
  nullable = false
}

variable "user_defined" {
  description = "A user-defined field that describes the Azure resource."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.user_defined) >= 2 && length(var.user_defined) <= 15
    error_message = "The user-defined field must be between 2-15 characters long."
  }
}

variable "naming_convention" {
  type        = string
  default     = "oss"
  description = "Sets which naming convention to use. Accepted values: oss, gc"
  validation {
    condition     = var.naming_convention == "oss" || var.naming_convention == "gc"
    error_message = "The naming_convention field must either be 'oss' or 'gc'."
  }
}

variable "tags" {
  description = "The tags to assign to the resources"
  type        = map(string)
  default     = {}
}

#######################
### Virtual Network ###
#######################

variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "The variable vnet_address_space must be written in CIDR notation."
  }
}

variable "vnet_peers" {
  description = "A list of remote virtual network resource IDs to use as virtual network peerings."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue(flatten([
      for resource_id in var.vnet_peers : [
        can(regex("^/subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Network/virtualNetworks/(.+)", resource_id))
      ]
    ]))

    error_message = "Each element within var.vnet_peers must be a valid Azure Virtual Network resource ID."
  }
}

variable "dns_servers" {
  description = "The IP addresses of the DNS servers to be used by the Azure virtual network. If no values specified, this defaults to Azure DNS."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "The DDoS protection plan resource id"
  type        = string
  default     = null
}

###############
### Subnets ###
###############

variable "subnets" {
  description = "The environment specific subnets to create in the virtual network."
  type = map(object({
    address_prefixes = list(string)

    nsg_id     = optional(string)
    create_nsg = optional(bool, true)
    extra_nsg_rules = optional(list(object({
      name                                       = string
      description                                = string
      protocol                                   = string                 # Tcp, Udp, Icmp, Esp, Ah or *
      access                                     = string                 # Allow or Deny
      priority                                   = number                 # The value can be between 100 and 4096
      direction                                  = string                 # Inbound or Outbound
      source_port_range                          = optional(string)       # between 0 and 65535 or * to match any
      source_port_ranges                         = optional(list(string)) # required if source_port_range is not specified
      destination_port_range                     = optional(string)       # between 0 and 65535 or * to match any
      destination_port_ranges                    = optional(list(string)) # required if destination_port_range is not specified
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string)) # required if source_address_prefix is not specified.
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string)) #  required if destination_address_prefix is not specified
      destination_application_security_group_ids = optional(list(string))
    })), [])

    route_table_id        = optional(string)
    associate_route_table = optional(bool, true)

    service_endpoints = optional(list(string))
    service_endpoint_policy_definitions = optional(list(object({ # No policy is created if unspecified
      name        = optional(string)
      description = optional(string)
      service     = optional(string, "Microsoft.Storage")
      scopes      = list(string)
    })))

    service_delegation_name                       = optional(string)
    private_endpoint_network_policies_enabled     = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
  }))

  validation {
    condition = (
      contains(keys(var.subnets), "RouteServerSubnet") &&
      contains(keys(var.subnets), "apiserver") &&
      contains(keys(var.subnets), "loadbalancer") &&
      contains(keys(var.subnets), "gateway") &&
      contains(keys(var.subnets), "system") &&
      contains(keys(var.subnets), "general") &&
      contains(keys(var.subnets), "infrastructure")
    )
    error_message = "Each Cloud Native Platform virtual network must contain the RouteServerSubnet, apiserver, loadbalancer, gateway, system, general and infrastructure subnet."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in var.subnets : [
        for address_prefix in subnet.address_prefixes :
        can(cidrhost(address_prefix, 0))
      ]
    ]))
    error_message = "The argument address_prefixes must be written in CIDR notation."
  }
}

variable "route_table_next_hop_ip_address" {
  description = "The next hop ip address to add to the standard route table."
  type        = string
}

variable "extra_route_table_rules" {
  description = "The environment specific security rules to add to the standard route table."
  type        = list(string)
  default     = []
}

####################
### Route Server ###
####################

variable "route_server_bgp_peers" {
  description = "The details for creating BGP peer(s) within the route server."
  type = list(object({
    name     = string
    peer_asn = number
    peer_ip  = string
  }))
}
