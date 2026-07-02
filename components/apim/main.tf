module "ctags" {
  source       = "git::https://github.com/hmcts/terraform-module-common-tags.git?ref=master"
  environment  = var.env
  product      = var.product
  builtFrom    = var.builtFrom
  expiresAfter = var.expiresAfter
}

module "api-mgmt" {
  source                               = "git::https://github.com/hmcts/cnp-module-api-mgmt-private.git?ref=change/top_level_domain"
  location                             = var.location
  sku_name                             = var.apim_sku_name
  virtual_network_resource_group       = local.vnet_rg
  virtual_network_name                 = local.vnet_name
  environment                          = var.env
  virtual_network_type                 = "Internal"
  additional_routes_apim               = var.additional_routes_apim
  department                           = var.department
  common_tags                          = module.ctags.common_tags
  route_next_hop_in_ip_address         = var.networking.hub.next_hop_ip
  publisher_email                      = var.publisher_email
  disable_trusted_service_connectivity = var.disable_trusted_service_connectivity
  custom_nsg_rules                     = var.apim_custom_nsg_rules
  cert_domain                          = "api"
  custom_top_level_domain              = "api.hmcts.net"
  developer_portal = {
    sign_in_enabled = true
    sign_up         = null
    custom_domain = {
      fqdn         = var.developer_portal.custom_domain_name
      key_vault_id = var.developer_portal.key_vault_id
      cert_name    = var.developer_portal.cert_name
    }
  }
  management = {
    fqdn         = var.management.custom_domain_name
    key_vault_id = var.management.key_vault_id
    cert_name    = var.management.cert_name
  }
}

resource "azurerm_api_management_named_value" "environment" {
  name                = "environment"
  resource_group_name = local.vnet_rg
  api_management_name = module.api-mgmt.name
  display_name        = "environment"
  value               = var.env
}

data "azurerm_key_vault_certificate" "portal" {
  count        = var.developer_portal.custom_domain_name != null ? 1 : 0
  name         = var.developer_portal.cert_name
  key_vault_id = var.developer_portal.key_vault_id
}
