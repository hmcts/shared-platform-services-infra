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

# Configuration for cross-tenant VNet peering providers and peering targets.
# Subscription ID defaults match the known sbox/nonlive values and can be overridden per environment.
variable "cross_tenant_peering" {
  type = object({
    # The CNP (hmcts) subscription that contains the SPS VNet to peer from
    cnp_subscription_id = optional(string, "bd2864ed-4f3e-45ed-9c6a-8d179674bab1")
    # The CPP non-live subscription that contains the target VNet to peer to
    cpp_subscription_id = optional(string, "e6b5053b-4c38-4475-a835-a025aeb3d8c7")
    # Map of VNet peerings to create — key is a logical name used as the Terraform resource key
    peerings = optional(map(object({
      source_name = string # Name of the peering link on the CNP/SPS side
      target_name = string # Name of the peering link on the CPP side
      vnet_name   = string # Name of the target VNet in the CPP subscription
      rg_name     = string # Resource group of the target VNet in the CPP subscription
    })), {})
  })
  description = "Configuration for cross-tenant VNet peering providers and peering targets."
  default     = {}
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

variable "publisher_email" {
  description = "The email address of the APIM publisher."
  type        = string
  default     = "DTSPlatformOperations@justice.gov.uk"
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

variable "developer_portal" {
  description = "Configuration for the APIM developer portal custom domain and certificate"
  type = object({
    custom_domain_name = optional(string)
    key_vault_id       = optional(string)
    cert_name          = optional(string)
  })
  default = {}
}

variable "management" {
  description = "Configuration for the APIM management custom domain and certificate"
  type = object({
    custom_domain_name = optional(string)
    key_vault_id       = optional(string)
    cert_name          = optional(string)
  })
  default = {}
}

variable "deploy_extid_rg" {
  description = "Whether to deploy the external identity resource group"
  type        = bool
  default     = false
}
