# Least-privilege role allowing an identity to manage APIM subscriptions (keys) without broader APIM contributor rights.
resource "azurerm_role_definition" "apim_subscription_manager" {
  count       = length(var.apim_subscription_managers) > 0 ? 1 : 0
  name        = "SPS APIM Subscription Manager (${var.env})"
  scope       = module.api-mgmt.id
  description = "List, read keys, create and delete subscriptions on ${module.api-mgmt.name}."

  permissions {
    actions = [
      "Microsoft.ApiManagement/service/subscriptions/read",
      "Microsoft.ApiManagement/service/subscriptions/write",
      "Microsoft.ApiManagement/service/subscriptions/delete",
      "Microsoft.ApiManagement/service/subscriptions/listSecrets/action",
    ]
  }

  assignable_scopes = [module.api-mgmt.id]
}

resource "azurerm_role_assignment" "apim_subscription_manager" {
  for_each           = var.apim_subscription_managers
  scope              = module.api-mgmt.id
  role_definition_id = azurerm_role_definition.apim_subscription_manager[0].role_definition_resource_id
  principal_id       = each.value
  principal_type     = "ServicePrincipal"
}
