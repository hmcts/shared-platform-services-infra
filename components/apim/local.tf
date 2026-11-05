locals {
  vnet_rg    = "rg-${var.product}-${local.naming_env}"
  vnet_name  = "${var.product}-networking-vnet-${local.naming_env}"
  naming_env = var.env == "dev" ? "preview" : var.env == "test" ? "perftest" : var.env == "stg" ? "aat" : var.env

  fqdn_map = {
    "prod" = ""
    "stg"  = "aat"
    "sbox" = "sandbox"
    "dev"  = "preview"
  }
}
data "azurerm_key_vault_certificate" "certificate" {
  count        = var.gateway_hostname.cert_name != null && var.gateway_hostname.key_vault_id != null ? 1 : 0
  name         = var.gateway_hostname.cert_name
  key_vault_id = var.gateway_hostname.key_vault_id
}
