# Variables that have default values and are not required to be set by the user. These can be overridden if needed, but will not cause an error if left unset.

variable "location" {
  type    = string
  default = "UK South"
}

variable "networking" {
  type = object({
    hub = optional(object({
      next_hop_ip         = optional(string, "10.11.72.36")
      subscription_id     = optional(string, "fb084706-583f-4c9a-bdab-949aac66ba5c")
      vnet_name           = optional(string, "hmcts-hub-nonprodi")
      resource_group_name = optional(string, "hmcts-hub-nonprodi")
    }))
    vpn = optional(object({
      subscription_id     = optional(string, "ed302caf-ec27-4c64-a05e-85731c3ce90e")
      vnet_name           = optional(string, "mgmt-vpn-2-vnet")
      resource_group_name = optional(string, "mgmt-vpn-2-mgmt")
    }))
  })
  description = "Networking configuration for the virtual network."
  default = {
    hub = {}
    vpn = {}
  }
}
