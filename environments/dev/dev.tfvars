project      = "spshmcts"
location     = "uksouth"
env          = "dev"
subscription = "preview"
autoShutdown = true

ssl_policy = {
  policy_type          = "Predefined"
  policy_name          = "AppGwSslPolicy20220101S"
  min_protocol_version = "TLSv1_2"
}

hub_app_gw_private_ip_address = ["10.180.5.10"]
apim_appgw_backend_pool_ips   = ["10.180.4.4"]
apim_appgw_backend_pool_fqdns = []

networking = {
  hub = {
    next_hop_ip         = "10.11.72.36"
    subscription_id     = "fb084706-583f-4c9a-bdab-949aac66ba5c"
    vnet_name           = "hmcts-hub-nonprodi"
    resource_group_name = "hmcts-hub-nonprodi"
  }
  vpn = {}
}

developer_portal = {
  custom_domain_name = "amp-portal.preview.api.hmcts.net"
  key_vault_id       = "/subscriptions/7cfd7e05-06a1-4d9b-a426-db304bc99aab/resourceGroups/sps-platform-dev-rg/providers/Microsoft.KeyVault/vaults/acmedtsspspreview"
  cert_name          = "amp-portal-preview-api-hmcts-net"
}

management = {
  custom_domain_name = "management.preview.api.hmcts.net"
  key_vault_id       = "/subscriptions/7cfd7e05-06a1-4d9b-a426-db304bc99aab/resourceGroups/sps-platform-dev-rg/providers/Microsoft.KeyVault/vaults/acmedtsspspreview"
  cert_name          = "wildcard-preview-api-hmcts-net"
}

deploy_extid_rg = false

apim_diagnostic_settings = {
  frontend_request_body_bytes  = 8192
  frontend_response_body_bytes = 8192
  backend_request_body_bytes   = 8192
  backend_response_body_bytes  = 8192
}

cross_tenant_peering = {
  cnp_subscription_id = "7cfd7e05-06a1-4d9b-a426-db304bc99aab" # DTS-SPS-PREVIEW
  cpp_subscription_id = "e6b5053b-4c38-4475-a835-a025aeb3d8c7" # CPP Strategic Platform - non-live

  peerings = {
    "vn-sit-svc-01" = {
      source_name = "sps-platform-networking-vnet-preview-to-cpp-nonlive-vn-sit-svc-01"
      target_name = "cpp-nonlive-vn-sit-svc-01-to-sps-platform-networking-vnet-preview"
      vnet_name   = "VN-SIT-SVC-01"
      rg_name     = "RG-SIT-SVC-01"
    }
  }
}
