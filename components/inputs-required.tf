variable "env" {
  type = string
}

variable "builtFrom" {
  type = string
}

variable "product" {
  type = string
}

variable "networking" {
  type = object({
    next_hop_ip = string
    hub = optional(object({
      subscription_id     = optional(string, "fb084706-583f-4c9a-bdab-949aac66ba5c")
      vnet_name           = optional(string, "hmcts-hub-nonprodi")
      resource_group_name = optional(string, "hmcts-hub-nonprodi")
    }))
  })
  description = "Networking configuration for the virtual network."
}
