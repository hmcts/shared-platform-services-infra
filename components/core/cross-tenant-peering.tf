locals {
  cross_tenant_client_id     = try(data.azurerm_key_vault_secret.multi_tenant_client_id.value, null)
  cross_tenant_client_secret = try(data.azurerm_key_vault_secret.multi_tenant_client_secret.value, null)
  cross_tenant_aux_tenant_ids = ["531ff96d-0ae9-462a-8d2d-bec7c0b42082"]
}


data "azurerm_key_vault" "central_app_registration" {
  provider = azurerm.central-app-kv

  name                = "central-app-reg-kv"
  resource_group_name = "central-app-registration-rg"
}

data "azurerm_key_vault_secret" "multi_tenant_client_id" {
  name         = "nonlive-crime-idam-cross-tenant-app-id"
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

data "azurerm_key_vault_secret" "multi_tenant_client_secret" {
  name         = "nonlive-crime-idam-cross-tenant-secret"
  key_vault_id = data.azurerm_key_vault.central_app_registration.id
}

provider "azurerm" {
  alias                      = "central-app-kv"
  features {}
  skip_provider_registration = true
  subscription_id            = "6c4d2513-a873-41b4-afdd-b05a33206631" # Central App Registration subscription
}

provider "azurerm" {
  alias = "CNP-Sbox"
  features {}
  skip_provider_registration = true

  subscription_id      = "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" # DTS-SPS-SBOX
  client_id            = local.cross_tenant_client_id
  client_secret        = local.cross_tenant_client_secret
  tenant_id            = "531ff96d-0ae9-462a-8d2d-bec7c0b42082" # CNP Tenant ID
  auxiliary_tenant_ids = ["e2995d11-9947-4e78-9de6-d44e0603518e"] # CPP Nonlive Tenant ID
}

provider "azurerm" {
  alias = "CPP-Nonlive"
  features {}
  skip_provider_registration = true

  subscription_id      = "e6b5053b-4c38-4475-a835-a025aeb3d8c7" # CPP Strategic Platform - non-live subscription
  tenant_id            = "e2995d11-9947-4e78-9de6-d44e0603518e" # CPP Nonlive Tenant ID
  client_id            = local.cross_tenant_client_id
  client_secret        = local.cross_tenant_client_secret
  auxiliary_tenant_ids = local.cross_tenant_aux_tenant_ids
}

module "cross_tenant_peering" {

  count = var.env == "sbox" ? 1 : 0

  source = "../../modules/cross-tenant-peering"

  providers = {
    azurerm.initiator = azurerm.CNP-Sbox
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