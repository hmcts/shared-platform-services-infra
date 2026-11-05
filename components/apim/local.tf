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
  name         = local.gateway_hostname.cert_name
  key_vault_id = local.gateway_hostname.key_vault_id
}
