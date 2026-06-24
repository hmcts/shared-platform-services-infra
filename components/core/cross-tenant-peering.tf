locals {
  nonprodi_cross_tenant_enabled = var.env == "sbox"

  # Shared cross-tenant credentials (only populated when nonprodi_cross_tenant_enabled)
  cross_tenant_client_id     = local.nonprodi_cross_tenant_enabled ? try(data.azurerm_key_vault_secret.multi_tenant_client_id[0].value, null) : null
  
  cross_tenant_client_secret = local.nonprodi_cross_tenant_enabled ? try(data.azurerm_key_vault_secret.multi_tenant_client_secret[0].value, null) : null
  
  cross_tenant_aux_tenant_ids = local.nonprodi_cross_tenant_enabled ? compact([
    try(data.azurerm_key_vault_secret.cnp_nonprod_hub_tenant_id[0].value, null)
  ]) : []
}


data "azurerm_key_vault" "central_app_registration" {
  count = var.env == "sbox" ? 1 : 0
  
  provider = azurerm.central-app-kv

  name                = "central-app-reg-kv"
  resource_group_name = "central-app-registration-rg"

}

data "azurerm_key_vault" "hub_azure_keyvault" {
  count = var.env == "sbox" ? 1 : 0

  name                = "hmcts-infra-hub-${var.env}-int"
  resource_group_name = "hmcts-infra-hub-${var.env}-int"
}


data "azurerm_key_vault_secret" "multi_tenant_client_id" {
  count = var.env == "sbox" ? 1 : 0

  name         = "nonlive-crime-vn-ste-svc-01-cross-tenant-app-id"
  key_vault_id = data.azurerm_key_vault.central_app_registration[0].id
}

data "azurerm_key_vault_secret" "multi_tenant_client_secret" {
  count = var.env == "sbox" ? 1 : 0

  name         = "nonlive-crime-vn-ste-svc-01-cross-tenant-secret"
  key_vault_id = data.azurerm_key_vault.central_app_registration[0].id
}

# CNP Tenant ID
data "azurerm_key_vault_secret" "cnp_nonprod_hub_tenant_id" {
  count = var.env == "sbox" ? 1 : 0

  name         = "cnp-nonprod-hub-tenant-id"
  key_vault_id = data.azurerm_key_vault.hub_azure_keyvault[0].id
}

# TBC - CPP Tenant ID
data "azurerm_key_vault_secret" "cpp_nonlive_tenant_id" {
  count = var.env == "sbox" ? 1 : 0

  name         = "cpp-nonlive-hub-tenant-id"
  key_vault_id = data.azurerm_key_vault.hub_azure_keyvault[0].id
}

# TBC - CNP Subscription ID
data "azurerm_key_vault_secret" "cpp_nonlive_subscription_id" {
  count = var.env == "sbox" ? 1 : 0

  name         = "cpp-nonlive-subscription-id"
  key_vault_id = data.azurerm_key_vault.hub_azure_keyvault[0].id
}

data "azurerm_key_vault_secret" "cnp-sbox-sps-platform-subscription-id" {
  count = var.env == "sbox" ? 1 : 0

  name         = "cnp-sbox-sps-platform-subscription-id"
  key_vault_id = data.azurerm_key_vault.hub_azure_keyvault[0].id
}

provider "azurerm" {
  alias = "central-app-kv"
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "6c4d2513-a873-41b4-afdd-b05a33206631"
}

provider "azurerm" {
  alias = "CNP-NonProd"
  features {}
  resource_provider_registrations = local.nonprodi_cross_tenant_enabled ? "core" : "none"

  subscription_id      = data.azurerm_key_vault_secret.cnp-sbox-sps-platform-subscription-id[0].value
  client_id            = local.cross_tenant_client_id
  client_secret        = local.cross_tenant_client_secret
  tenant_id            = try(data.azurerm_key_vault_secret.cnp_nonprod_hub_tenant_id[0].value, null)
  auxiliary_tenant_ids = compact([try(data.azurerm_key_vault_secret.cpp_nonlive_tenant_id[0].value, null)])
}

provider "azurerm" {
  alias = "CPP-Nonlive"
  features {}
  resource_provider_registrations = local.nonprodi_cross_tenant_enabled ? "core" : "none"

  subscription_id      = try(data.azurerm_key_vault_secret.cpp_nonlive_subscription_id[0].value, data.azurerm_key_vault_secret.cnp-sbox-sps-platform-subscription-id[0].value)
  tenant_id            = try(data.azurerm_key_vault_secret.cpp_nonlive_tenant_id[0].value, data.azurerm_client_config.current.tenant_id)
  client_id            = local.cross_tenant_client_id
  client_secret        = local.cross_tenant_client_secret
  auxiliary_tenant_ids = local.cross_tenant_aux_tenant_ids
}

module "cross_tenant_peering" {

  count = var.env == "sbox" ? 1 : 0

  source = "../../modules/cross-tenant-peering"

  providers = {
    azurerm.initiator = azurerm.CNP-NonProd
    azurerm.target    = azurerm.CPP-Nonlive
  }

  source_vnet_name      = module.networking.vnet_names["vnet"]
  source_resource_group = module.networking.resource_group_name

  # CPP Nonlive peering targets
  peerings = {
    "vn-ste-svc-01" = {
      source_name = "${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}-to-cpp-nonlive-vn-ste-svc-01"
      target_name = "cpp-nonlive-vn-ste-svc-01-to-${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}"
      vnet_name   = "VN-STE-SVC-01"
      rg_name     = "RG-STE-SVC-01"
    }
  }
}
