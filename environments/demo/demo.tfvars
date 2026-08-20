project      = "spshmcts"
location     = "uksouth"
env          = "demo"
subscription = "demo"
cdn_sku      = "Standard_Verizon"
sku_tier     = "Free"
sku_size     = "Free"
autoShutdown = true

ssl_policy = {
  policy_type          = "Predefined"
  policy_name          = "AppGwSslPolicy20220101S"
  min_protocol_version = "TLSv1_2"
}

//hub_app_gw_private_ip_address = ["10.180.1.10"]
//apim_appgw_backend_pool_ips   = ["10.180.0.4"]
//apim_appgw_backend_pool_fqdns = []

networking = {
  hub = {
    next_hop_ip         = "10.11.72.36"
    subscription_id     = "fb084706-583f-4c9a-bdab-949aac66ba5c"
    vnet_name           = "hmcts-hub-nonprodi"
    resource_group_name = "hmcts-hub-nonprodi"
  }
  vpn = {}
}

deploy_extid_rg = false

apim_diagnostic_settings = {
  frontend_request_body_bytes  = 8192
  frontend_response_body_bytes = 8192
  backend_request_body_bytes   = 8192
  backend_response_body_bytes  = 8192
}
