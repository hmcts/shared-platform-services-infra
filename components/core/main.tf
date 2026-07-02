locals {
  naming_env = var.env == "dev" ? "preview" : var.env == "test" ? "perftest" : var.env == "stg" ? "aat" : var.env

  # azure-private-dns uses a different service connection in sandbox.
  private_dns_pipeline_principal_ids = var.env == "sbox" ? toset([
    "b8f08f77-4ce2-43d5-a23b-c7ca735eca02", # dts-cftptl-intsvc
    "2070d748-c35c-478f-a5ca-ec8a5c4ff10d"  # dts-cftsbox-intsvc
    ]) : toset([
    "b8f08f77-4ce2-43d5-a23b-c7ca735eca02"
  ])

  role_assignments = merge(var.env != "prod" ? {
    "api_marketplace-apim" = {
      scope                = azurerm_resource_group.this.id
      role_definition_name = var.env == "sbox" ? "Contributor" : "Reader"
      principal_id         = data.azuread_group.api_marketplace.object_id
    }
    } : {}, var.deploy_extid_rg ? {
    "api_marketplace-extid" = {
      scope                = azurerm_resource_group.extid.id
      role_definition_name = var.env == "sbox" ? "Contributor" : "Reader"
      principal_id         = data.azuread_group.api_marketplace.object_id
    }
  } : {})
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.product}-${local.naming_env}"
  location = var.location
  tags     = module.ctags.common_tags
}

resource "azurerm_resource_group" "extid" {
  count    = var.deploy_extid_rg ? 1 : 0
  name     = "rg-${var.product}-extid-${local.naming_env}"
  location = var.location
  tags     = module.ctags.common_tags
}

# Grant the azure-private-dns pipeline SPN Network Contributor on the SPS platform VNet.
# SPN object ID: b8f08f77-4ce2-43d5-a23b-c7ca735eca02 (DTS Bootstrap)
resource "azurerm_role_assignment" "private_dns_vnet_join" {
  for_each             = local.private_dns_pipeline_principal_ids
  scope                = module.networking.vnet_ids["vnet"]
  role_definition_name = "Network Contributor"
  principal_id         = each.value
  description          = "Allow private-dns pipeline SPN to link internal.hmcts.net zones to this VNet"
}

resource "azurerm_role_assignment" "rbac" {
  for_each             = local.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
