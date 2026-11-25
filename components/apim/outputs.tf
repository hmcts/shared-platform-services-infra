output "apim_name" {
  description = "The name of the APIM service. Used by the portal deployment pipeline stage."
  value       = module.api-mgmt.name
}

output "resource_group_name" {
  description = "The resource group containing the APIM service. Used by the portal deployment pipeline stage."
  value       = local.vnet_rg
}

output "token_exchange_identity" {
  description = "The APIM token exchange identity. client_id goes in API policies; principal_id is the subject of federated credentials that trust it."
  value = var.apim_token_exchange_identity_enabled ? {
    name         = azurerm_user_assigned_identity.token_exchange[0].name
    client_id    = azurerm_user_assigned_identity.token_exchange[0].client_id
    principal_id = azurerm_user_assigned_identity.token_exchange[0].principal_id
  } : null
}
