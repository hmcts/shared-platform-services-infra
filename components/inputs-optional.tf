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

# Declared to satisfy the shared tfvars file; not used directly in components
variable "destinations" { default = {} }
variable "frontends" { default = {} }
variable "private_ip_address" { default = "" }

variable "traffic_manager_endpoints" { default = {} }
variable "traffic_manager_profiles" { default = {} }
variable "shutter_rg" { default = "" }
variable "cdn_sku" { default = "" }
variable "department" { default = "sps" }
variable "apim_sku_name" { default = "Developer" }
variable "hub" { default = "sbox" }
variable "ssl_policy" { default = null }

variable "key_vault_subscription" {
  default = null
}

variable "hub_app_gw_private_ip_address" {
  default = []
}

variable "apim_appgw_backend_pool_ips" {
  default = []
}

variable "apim_appgw_backend_pool_fqdns" {
  default = []
}

variable "apim_appgw_exclusions" {
  default = []
}

variable "apim_appgw_min_capacity" {
  default = 2
}

variable "apim_appgw_max_capacity" {
  default = 10
}

variable "additional_routes_apim" {
  description = "A list of additional routes configurations"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
  default = []
}

variable "waf_mode" {
  default = "Detection"
}

variable "expiresAfter" {
  description = "Date when Sandbox resources can be deleted. Format: YYYY-MM-DD"
  default     = "3000-01-01"
}

variable "autoShutdown" {
  default = false
}

variable "ssl_mode" {
  default = "FrontDoor"
}

variable "send_access_logs_to_log_analytics" {
  description = "Whether to send access logs to log analytics workspace"
  type        = bool
  default     = false
}

variable "disable_trusted_service_connectivity" {
  description = "Disable Trusted Service Connectivity for APIM"
  type        = bool
  default     = false
}

variable "apim_custom_nsg_rules" {
  description = "A map of custom NSG rules to apply in addition to the default rules to the APIM NSG"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = {}
}