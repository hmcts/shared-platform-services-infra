data "azurerm_key_vault" "central_app_registration" {
  provider = azurerm.central-app-kv

  name                = "central-app-reg-kv"
  resource_group_name = "central-app-registration-rg"
}

data "azurerm_key_vault_secret" "entra_id_app_id" {
  name         = var.identity_provider.app_id_secret_name
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

data "azurerm_key_vault_secret" "entra_id_app_secret" {
  name         = var.identity_provider.app_secret_secret_name
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

# User-assigned identity for token exchange: API policies use it (authentication-managed-identity
# with client-id) as a federated credential to sign in as an app, so no secret is stored.
# Attached alongside the system-assigned identity, which is kept for Key Vault and App Insights.
resource "azurerm_user_assigned_identity" "token_exchange" {
  count               = var.apim_token_exchange_identity_enabled ? 1 : 0
  name                = "sps-api-mgmt-token-exchange-${var.subscription}"
  resource_group_name = local.vnet_rg
  location            = var.location
  tags                = module.ctags.common_tags
}
