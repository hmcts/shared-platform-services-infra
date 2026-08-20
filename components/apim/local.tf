locals {
  vnet_rg    = "rg-${var.product}-${local.naming_env}"
  vnet_name  = "${var.product}-networking-vnet-${local.naming_env}"
  naming_env = var.env == "dev" ? "preview" : var.env == "test" ? "perftest" : var.env == "stg" ? "aat" : var.env
}
