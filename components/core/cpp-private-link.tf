# Private Endpoints to CPP Private Link Services (cross-tenant, connected by alias).
# Replaces VNet peering for the CPP WAF load balancers; see cross-tenant-peering.tf.
# DNS records for these endpoints are managed in a separate repository.

resource "azurerm_private_endpoint" "cpp" {
  for_each = var.cpp_private_link_endpoints

  name                = "pe-cpp-${each.key}-${local.naming_env}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.networking.subnet_ids["vnet-private-endpoints"]

  private_service_connection {
    name                              = "psc-cpp-${each.key}-${local.naming_env}"
    private_connection_resource_alias = each.value.pls_alias
    is_manual_connection              = true
    request_message                   = each.value.request_message
  }

  tags = module.ctags.common_tags
}
