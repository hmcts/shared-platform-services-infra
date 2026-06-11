locals {
  naming_env = var.env == "dev" ? "preview" : var.env == "test" ? "perftest" : var.env == "stg" ? "aat" : var.env
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.product}-${local.naming_env}"
  location = var.location
  tags     = module.ctags.common_tags
}

# Grant the azure-private-dns pipeline SPN Network Contributor on the SPS platform VNet.
# SPN object ID: b8f08f77-4ce2-43d5-a23b-c7ca735eca02 (DTS Bootstrap)
resource "azurerm_role_assignment" "private_dns_vnet_join" {
  scope                = module.networking.vnet_ids["vnet"]
  role_definition_name = "Network Contributor"
  principal_id         = "b8f08f77-4ce2-43d5-a23b-c7ca735eca02"
  description          = "Allow private-dns pipeline SPN to link internal.hmcts.net zones to this VNet"
}
