locals {
  naming_env = var.env == "dev" ? "preview" : var.env == "test" ? "perftest" : var.env == "stg" ? "aat" : var.env
}
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.product}-${local.naming_env}"
  location = var.location
  tags     = module.ctags.common_tags
}
