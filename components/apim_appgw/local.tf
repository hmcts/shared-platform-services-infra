locals {
  env = var.env

  vnet_rg     = "rg-${var.product}-${var.env}"
  vnet_name   = "${var.product}-networking-vnet-${var.env}"
  subnet_name = "${var.product}-networking-app-gateway-${var.env}"

  key_vault_resource_group = "sps-platform-${var.subscription}-rg"
  key_vault_subscription   = var.key_vault_subscription

  # To be removed once the TLS1.0/1.1 deprecation is complete
  current_ssl_policy = {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20150501"
  }
}
