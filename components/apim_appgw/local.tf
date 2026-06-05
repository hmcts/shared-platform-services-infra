locals {
  env = var.env

  vnet_rg     = (var.env == "dev") ? "rg-sps-platform-preview" : (var.env == "test") ? "rg-sps-platform-perftest" : (var.env == "stg") ? "rg-sps-platform-aat" : "rg-sps-platform-${var.env}"
  vnet_name   = (var.env == "dev") ? "sps-platform-networking-vnet-preview" : (var.env == "test") ? "rsps-platform-networking-vnet-perftest" : (var.env == "stg") ? "sps-platform-networking-vnet-aat" : "sps-platform-networking-vnet-${var.env}"
  subnet_name = "vnet-app-gateway"
  hub_env     = (var.env == "demo" || var.env == "dev" || var.env == "ithc" || var.env == "test") ? "nonprod" : (var.env == "stg") ? "prod" : var.env

  key_vault_resource_group = "sps-platform-${var.subscription}-rg"
  key_vault_subscription   = var.key_vault_subscription

  # To be removed once the TLS1.0/1.1 deprecation is complete
  current_ssl_policy = {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20150501"
  }


  hub = {
    sbox = {
      subscription = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
      ukSouth = {
        name              = "hmcts-hub-sbox-int"
        next_hop_ip       = "10.10.200.36"
        appgw_next_hop_ip = "20.90.242.134" # Azure Firewall
      }
    }
    nonprod = {
      subscription = "fb084706-583f-4c9a-bdab-949aac66ba5c"
      ukSouth = {
        name        = "hmcts-hub-nonprodi"
        next_hop_ip = "10.11.72.36"
      }
    }
    prod = {
      subscription = "0978315c-75fe-4ada-9d11-1eb5e0e0b214"
      ukSouth = {
        name        = "hmcts-hub-prod-int"
        next_hop_ip = "10.11.8.36"
      }
    }
  }
}
