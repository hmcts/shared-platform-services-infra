# Shared CP token exchange, included by API policies that call a CP backend behind the oauth gateway.
# Each API sets cpAudience (and optionally cpRejectUnmapped) before <include-fragment fragment-id="cp-token-exchange" />.
# Apply this before any API policy that includes it: APIM rejects a policy that names a missing fragment.
resource "azurerm_api_management_policy_fragment" "cp_token_exchange" {
  count = var.cp_token_exchange != null ? 1 : 0

  api_management_id = module.api-mgmt.id
  name              = "cp-token-exchange"
  format            = "xml"
  description       = "Swaps the consumer's validated external token for a CP token for that consumer's CP-access app."

  value = templatefile("${path.module}/policies/cp-token-exchange-fragment.xml.tftpl", {
    cp_tenant_id         = var.cp_token_exchange.tenant_id
    identity_client_id   = azurerm_user_assigned_identity.token_exchange[0].client_id
    client_map           = var.cp_token_exchange.client_map
    cache_buffer_seconds = var.cp_token_exchange.cache_buffer_seconds
  })

  lifecycle {
    precondition {
      condition     = var.apim_token_exchange_identity_enabled
      error_message = "cp_token_exchange needs apim_token_exchange_identity_enabled = true: the fragment signs in with that identity."
    }
  }

  depends_on = [module.api-mgmt]
}
