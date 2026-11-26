# Owns the APIM global policy. Enable per environment only after reading the
# live policy there, since this replaces it for every API on the instance.
resource "azurerm_api_management_policy" "global" {
  count = var.global_policy_enabled ? 1 : 0

  api_management_id = module.api-mgmt.id

  xml_content = templatefile("${path.module}/policies/global-policy.xml.tftpl", {
    developer_portal_domain = var.developer_portal.custom_domain_name
  })

  depends_on = [module.api-mgmt]
}
