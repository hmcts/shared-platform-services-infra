project            = "spshmcts"
location           = "uksouth"
env                = "sbox"
subscription       = "sbox"
oms_env            = "sandbox"
vnet_rg            = "rg-sps-platform-sbox"
vnet_name          = "sps-platform-networking-vnet-sbox"
cdn_sku            = "Standard_Verizon"
sku_tier           = "Free"
sku_size           = "Free"
autoShutdown       = true

ssl_policy = {
  policy_type          = "Predefined"
  policy_name          = "AppGwSslPolicy20220101S"
  min_protocol_version = "TLSv1_2"
}
ssl_certificate = "wildcard-sandbox-platform-hmcts-net"

hub_app_gw_private_ip_address = ["10.180.1.10"]
apim_appgw_backend_pool_fqdns = ["firewall-sbox-int-palo-spsapimgmt.uksouth.cloudapp.azure.com"]


networking = {
  hub = {
    next_hop_ip         = "10.10.200.36"
    subscription_id     = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
    vnet_name           = "hmcts-hub-sbox-int"
    resource_group_name = "hmcts-hub-sbox-int"
  }
  vpn = {}
}
