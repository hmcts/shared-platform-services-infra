data "azurerm_key_vault" "central_app_registration" {
  provider = azurerm.central-app-kv

  name                = "central-app-reg-kv"
  resource_group_name = "central-app-registration-rg"
}

data "azurerm_key_vault_secret" "entra_id_app_id" {
  name         = "api-marketplace-apim-nonprod-app-id"
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

data "azurerm_key_vault_secret" "entra_id_app_secret" {
  name         = "api-marketplace-apim-nonprod-secret"
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

data "azurerm_key_vault_secret" "entra_id_tenant_id" {
  name         = "tenant-id"
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

resource "azurerm_api_management_identity_provider_aad" "entra_id" {
  resource_group_name = local.vnet_rg
  api_management_name = module.api-mgmt.name
  client_id           = data.azurerm_key_vault_secret.entra_id_app_id.value
  client_secret       = data.azurerm_key_vault_secret.entra_id_app_secret.value
  allowed_tenants     = [data.azurerm_key_vault_secret.entra_id_tenant_id.value]
}
