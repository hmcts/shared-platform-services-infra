# Shared token exchange, included by API policies whose backend needs a token from another tenant.
# Each API sets tokenExchangeTenantId, tokenExchangeAudience, tokenExchangeAppId (from its own consumer map)
# and optionally tokenExchangeRejectUnmapped, then <include-fragment fragment-id="token-exchange" />.
# Apply this before any API policy that includes it: APIM rejects a policy that names a missing fragment.
resource "azurerm_api_management_policy_fragment" "token_exchange" {
  count = var.token_exchange != null ? 1 : 0

  api_management_id = module.api-mgmt.id
  name              = "token-exchange"
  format            = "xml"
  description       = "Swaps the consumer's validated external token for a backend-tenant token for that consumer's backend-access app."

  value = templatefile("${path.module}/policies/token-exchange-fragment.xml.tftpl", {
    identity_client_id   = azurerm_user_assigned_identity.token_exchange[0].client_id
    cache_buffer_seconds = var.token_exchange.cache_buffer_seconds
  })

  lifecycle {
    precondition {
      condition     = var.apim_token_exchange_identity_enabled
      error_message = "token_exchange needs apim_token_exchange_identity_enabled = true: the fragment signs in with that identity."
    }
  }

  depends_on = [module.api-mgmt]
}
