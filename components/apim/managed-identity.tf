resource "azurerm_user_assigned_identity" "token_translation" {
  count = var.apim_token_translation_identity_enabled ? 1 : 0

  name                = "sps-api-mgmt-${var.subscription}-token-translation"
  resource_group_name = local.vnet_rg
  location            = var.location
  tags                = module.ctags.common_tags
}
