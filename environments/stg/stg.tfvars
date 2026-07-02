project      = "spshmcts"
env          = "stg"
subscription = "aat"

networking = {
  hub = {
    next_hop_ip         = "10.11.8.36"
    subscription_id     = "0978315c-75fe-4ada-9d11-1eb5e0e0b214"
    vnet_name           = "hmcts-hub-prod-int"
    resource_group_name = "hmcts-hub-prod-int"
  }
  vpn = {}
}

deploy_extid_rg = true
