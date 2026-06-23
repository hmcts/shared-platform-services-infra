variable "source_vnet_name" {
  description = "Name of the source VNet"
  type        = string
}

variable "source_resource_group" {
  description = "Resource group of the source VNet"
  type        = string
}

variable "source_subnet_names" {
  description = "Names of the source subnets to peer (only required when peer_complete_virtual_networks_enabled is false)"
  type        = list(string)
  default     = []
}

variable "peerings" {
  description = "Map of cross-tenant peering targets"
  default     = {}
  type = map(object({
    vnet_name                              = string
    rg_name                                = string
    source_name                            = string
    target_name                            = string
    subnet_names                           = optional(list(string), [])
    peer_complete_virtual_networks_enabled = optional(bool, true)
  }))
}
