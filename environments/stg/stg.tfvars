project      = "spshmcts"
env          = "stg"
subscription = "aat"

# Managed identities allowed to manage APIM subscription keys on sps-api-mgmt-aat.
apim_subscription_managers = {
  # amp-aat-mi (managed-identities-aat-rg), used by service-api-marketplace
  service-api-marketplace = "6e337a81-8e59-4ae4-8feb-9108f9a49a27"
}

hub_app_gw_private_ip_address = ["10.180.21.10"]
apim_appgw_backend_pool_ips   = ["10.180.20.4"]
apim_appgw_backend_pool_fqdns = []
apim_sku_name                 = "Developer"
networking = {
  hub = {
    next_hop_ip         = "10.11.8.36"
    subscription_id     = "0978315c-75fe-4ada-9d11-1eb5e0e0b214"
    vnet_name           = "hmcts-hub-prod-int"
    resource_group_name = "hmcts-hub-prod-int"
  }
  vpn = {}
}

developer_portal = {
  custom_domain_name = "amp-portal.aat.api.hmcts.net"
  key_vault_id       = "/subscriptions/70bea6e3-384f-4cf4-b551-743a78d716cd/resourceGroups/sps-platform-stg-rg/providers/Microsoft.KeyVault/vaults/acmedtsspsstg"
  cert_name          = "amp-portal-aat-api-hmcts-net"
}

management = {
  custom_domain_name = "management.aat.api.hmcts.net"
  key_vault_id       = "/subscriptions/70bea6e3-384f-4cf4-b551-743a78d716cd/resourceGroups/sps-platform-stg-rg/providers/Microsoft.KeyVault/vaults/acmedtsspsstg"
  cert_name          = "wildcard-aat-api-hmcts-net"
}

deploy_extid_rg = true

apim_diagnostic_settings = {
  frontend_request_body_bytes  = 8192
  frontend_response_body_bytes = 8192
  backend_request_body_bytes   = 8192
  backend_response_body_bytes  = 8192
}

identity_provider = {
  app_id_secret_name     = "api-marketplace-apim-prod-app-id"
  app_secret_secret_name = "api-marketplace-apim-prod-secret"
}
