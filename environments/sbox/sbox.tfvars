project      = "spshmcts"
location     = "uksouth"
env          = "sbox"
subscription = "sbox"
# product            = "sps"
# builtFrom          = "hmcts/shared-platform-services-infra"
cdn_sku      = "Standard_Verizon"
sku_tier     = "Free"
sku_size     = "Free"
autoShutdown = true

ssl_policy = {
  policy_type          = "Predefined"
  policy_name          = "AppGwSslPolicy20220101S"
  min_protocol_version = "TLSv1_2"
}

hub_app_gw_private_ip_address = ["10.180.1.10"]
apim_appgw_backend_pool_fqdns = ["10.180.0.4"]


# Cross-tenant VNet peering subscription IDs.
# cnp_subscription_id: the DTS-SPS-SBOX subscription (CNP tenant) that contains the initiator VNet.
# cpp_subscription_id: the CPP Strategic Platform non-live subscription that contains the target VNet.
cross_tenant_peering = {
  cnp_subscription_id = "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" # DTS-SPS-SBOX
  cpp_subscription_id = "e6b5053b-4c38-4475-a835-a025aeb3d8c7" # CPP Strategic Platform - non-live

  # VNet peerings to create between the CNP/SPS sbox VNet and CPP non-live VNets.
  # Add additional entries here if more CPP VNets need to be peered.
  peerings = {
    "vn-ste-svc-01" = {
      source_name = "sps-platform-networking-vnet-sbox-to-cpp-nonlive-vn-ste-svc-01"
      target_name = "cpp-nonlive-vn-ste-svc-01-to-sps-platform-networking-vnet-sbox"
      vnet_name   = "VN-STE-SVC-01"
      rg_name     = "RG-STE-SVC-01"
    }
  }
}

networking = {
  hub = {
    next_hop_ip         = "10.10.200.36"
    subscription_id     = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
    vnet_name           = "hmcts-hub-sbox-int"
    resource_group_name = "hmcts-hub-sbox-int"
  }
  vpn = {}
}

developer_portal = {
  custom_domain_name = "amp-portal.sandbox.api.hmcts.net"
  key_vault_id       = "/subscriptions/bd2864ed-4f3e-45ed-9c6a-8d179674bab1/resourceGroups/sps-platform-sbox-rg/providers/Microsoft.KeyVault/vaults/acmedtsspssbox"
  cert_name          = "amp-portal-sandbox-api-hmcts-net"
}

deploy_extid_rg = true
