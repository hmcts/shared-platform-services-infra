locals {

  key_vault_resource_group = "sps-platform-${var.env}-rg"
  key_vault_subscription   = var.key_vault_subscription
  key_vault_name           = "acmedtssps${var.subscription == "aat" ? "stg" : var.subscription}"
  dns_zone                 = (var.env == "sbox") ? "sandbox" : var.env

  # To be removed once the TLS1.0/1.1 deprecation is complete
  current_ssl_policy = {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20150501"
  }
}
