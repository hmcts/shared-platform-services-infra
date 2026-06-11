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
  manage_route_table                   = false
  manage_nsg                           = false
  custom_top_level_domain              = "api.hmcts.net"

}

resource "azurerm_api_management_named_value" "environment" {
  name                = "environment"
  resource_group_name = local.vnet_rg
  api_management_name = module.api-mgmt.name
  display_name        = "environment"
  value               = var.env
}

# Disable the developer portal sign-in and sign-up by default.
# To re-enable, set enable_developer_portal = true in the environment tfvars.
# sign_in/sign_up are now blocks on azurerm_api_management in azurerm v4, but
# that resource is owned by the module. Use the ARM portalsettings sub-resources
# via azapi instead (the same pattern the module uses internally).
data "azurerm_api_management" "apim" {
  name                = module.api-mgmt.name
  resource_group_name = local.vnet_rg

  depends_on = [module.api-mgmt]
}

resource "azapi_resource" "apim_signin_settings" {
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signin"
  parent_id = data.azurerm_api_management.apim.id

  body = {
    properties = {
      enabled = var.enable_developer_portal
    }
  }

  depends_on = [module.api-mgmt]
}

resource "azapi_resource" "apim_signup_settings" {
  type      = "Microsoft.ApiManagement/service/portalsettings@2022-08-01"
  name      = "signup"
  parent_id = data.azurerm_api_management.apim.id

  body = {
    properties = {
      enabled = var.enable_developer_portal
      termsOfService = {
        enabled         = false
        consentRequired = false
        text            = ""
      }
    }
  }

  depends_on = [module.api-mgmt]
}