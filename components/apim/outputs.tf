output "apim_name" {
  description = "The name of the APIM service. Used by the portal deployment pipeline stage."
  value       = module.api-mgmt.name
}

output "resource_group_name" {
  description = "The resource group containing the APIM service. Used by the portal deployment pipeline stage."
  value       = local.vnet_rg
}

output "apim_token_translation_identity_id" {
  description = "Resource ID of the dedicated token-translation identity, or null when disabled."
  value       = one(azurerm_user_assigned_identity.token_translation[*].id)
}

output "apim_token_translation_identity_client_id" {
  description = "Client ID to select in APIM's authentication-managed-identity policy, or null when disabled."
  value       = one(azurerm_user_assigned_identity.token_translation[*].client_id)
}

output "apim_token_translation_identity_principal_id" {
  description = "Principal ID to use as the subject of an app registration's federated credential, or null when disabled."
  value       = one(azurerm_user_assigned_identity.token_translation[*].principal_id)
}
