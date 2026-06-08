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

# Look up the APIM resource to obtain its ID for portal configuration.
# The module only outputs the APIM name, so a data source is required.
data "azurerm_api_management" "apim" {
  name                = module.api-mgmt.name
  resource_group_name = "rg-${var.product}-${var.env}"
}

# Disable the developer portal sign-in and sign-up by default.
# To re-enable, set enable_developer_portal = true in the environment tfvars.
resource "azurerm_api_management_portal_config" "developer_portal" {
  count             = var.enable_developer_portal ? 0 : 1
  api_management_id = data.azurerm_api_management.apim.id

  sign_in {
    enabled = false
  }

  sign_up {
    enabled = false
    terms_of_service {
      enabled          = false
      consent_required = false
      text             = ""
    }
  }
}
