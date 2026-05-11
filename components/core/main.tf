resource "azurerm_resource_group" "this" {
  name     = "rg-${var.product}-${var.env}"
  location = var.location
  tags     = module.ctags.common_tags
}
