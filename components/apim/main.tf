module "ctags" {
  source       = "git::https://github.com/hmcts/terraform-module-common-tags.git?ref=master"
  environment  = var.env
  product      = var.product
  builtFrom    = var.builtFrom
  expiresAfter = var.expiresAfter
}

module "api-mgmt" {
  source                               = "git::https://github.com/hmcts/cnp-module-api-mgmt-private.git?ref=main"
  location                             = var.location
  sku_name                             = var.apim_sku_name
  virtual_network_resource_group       = "rg-${var.product}-${var.env}"
  virtual_network_name                 = "${var.product}-networking-vnet-${var.env}"
  environment                          = var.env
  virtual_network_type                 = "Internal"
  additional_routes_apim               = var.additional_routes_apim
  department                           = var.department
  common_tags                          = module.ctags.common_tags
  route_next_hop_in_ip_address         = var.networking.hub.next_hop_ip
  publisher_email                      = var.publisher_email
  disable_trusted_service_connectivity = var.disable_trusted_service_connectivity
  custom_nsg_rules                     = var.apim_custom_nsg_rules
}

resource "azurerm_api_management_named_value" "environment" {
  name                = "environment"
  resource_group_name = "rg-${var.product}-${var.env}"
  api_management_name = module.api-mgmt.name
  display_name        = "environment"
  value               = var.env
}

# Disable the developer portal sign-in and sign-up by default.
# To re-enable, set enable_developer_portal = true in the environment tfvars.
resource "azurerm_api_management_sign_in_settings" "developer_portal" {
  api_management_name = module.api-mgmt.name
  resource_group_name = "rg-${var.product}-${var.env}"
  enabled             = var.enable_developer_portal
}

resource "azurerm_api_management_sign_up_settings" "developer_portal" {
  api_management_name = module.api-mgmt.name
  resource_group_name = "rg-${var.product}-${var.env}"
  enabled             = var.enable_developer_portal

  terms_of_service {
    enabled          = false
    consent_required = false
    text             = ""
  }
}
