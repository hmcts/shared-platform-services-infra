locals {
  cross_tenant_client_id      = try(data.azurerm_key_vault_secret.multi_tenant_client_id.value, null)
  cross_tenant_client_secret  = try(data.azurerm_key_vault_secret.multi_tenant_client_secret.value, null)
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
  alias = "central-app-kv"
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "6c4d2513-a873-41b4-afdd-b05a33206631" # Central App Registration subscription
}

provider "azurerm" {
  alias = "cnp-azurerm-provider"
  features {}
  resource_provider_registrations = "none"

  subscription_id      = var.cross_tenant_peering.cnp_subscription_id # CNP subscription containing the SPS VNet (set via cross_tenant_peering variable)
  client_id            = local.cross_tenant_client_id                 #
  client_secret        = local.cross_tenant_client_secret
  tenant_id            = "531ff96d-0ae9-462a-8d2d-bec7c0b42082"   # CNP Tenant ID
  auxiliary_tenant_ids = ["e2995d11-9947-4e78-9de6-d44e0603518e"] # CPP Nonlive Tenant ID
}

provider "azurerm" {
  alias = "cpp-nonlive-azurerm-provider"
  features {}
  resource_provider_registrations = "none"

  subscription_id      = var.cross_tenant_peering.cpp_subscription_id # CPP subscription containing the target VNet (set via cross_tenant_peering variable)
  tenant_id            = "e2995d11-9947-4e78-9de6-d44e0603518e"       # CPP Nonlive Tenant ID
  client_id            = local.cross_tenant_client_id
  client_secret        = local.cross_tenant_client_secret
  auxiliary_tenant_ids = local.cross_tenant_aux_tenant_ids
}

# Logic below needs to be updated. Currently, the cross-tenant peering module is only used in sbox, but it should be updated to support other environments in the future.
module "cross_tenant_peering" {

  count = var.env == "sbox" ? 1 : 0

  source = "../../modules/cross-tenant-peering"

  providers = {
    azurerm.initiator = azurerm.cnp-azurerm-provider
    azurerm.target    = azurerm.cpp-nonlive-azurerm-provider
  }

  source_vnet_name      = module.networking.vnet_names["vnet"]
  source_resource_group = module.networking.resource_group_name

  # CPP Nonlive peering targets — defined per environment in the cross_tenant_peering.peerings tfvars variable
  peerings = var.cross_tenant_peering.peerings
}
