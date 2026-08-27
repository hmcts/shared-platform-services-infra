
project      = "spshmcts"
env          = "prod"
subscription = "prod"

ssl_policy = {
  policy_type          = "Predefined"
  policy_name          = "AppGwSslPolicy20220101S"
  min_protocol_version = "TLSv1_2"
}

hub_app_gw_private_ip_address = ["10.180.25.10"]
apim_appgw_backend_pool_ips   = ["10.180.24.4"]
apim_appgw_backend_pool_fqdns = []

apim_sku_name = "Premium"

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
  custom_domain_name = "amp-portal.api.hmcts.net"
  key_vault_id       = "/subscriptions/890625e2-7a8b-445c-81b4-8044a062cef3/resourceGroups/sps-platform-prod-rg/providers/Microsoft.KeyVault/vaults/acmedtsspsprod"
  cert_name          = "amp-portal-api-hmcts-net"
}

management = {
  custom_domain_name = "management.api.hmcts.net"
  key_vault_id       = "/subscriptions/890625e2-7a8b-445c-81b4-8044a062cef3/resourceGroups/sps-platform-prod-rg/providers/Microsoft.KeyVault/vaults/acmedtsspsprod"
  cert_name          = "wildcard-api-hmcts-net"
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
