module "cross_tenant_peering" {
  for_each = var.peerings
  source   = "github.com/hmcts/terraform-module-vnet-peering?ref=master"

  peer_complete_virtual_networks_enabled = each.value.peer_complete_virtual_networks_enabled

  peerings = {
    source = {
      name           = each.value.source_name
      vnet           = var.source_vnet_name
      resource_group = var.source_resource_group
      subnet_names   = each.value.peer_complete_virtual_networks_enabled ? null : var.source_subnet_names
    }
    target = {
      name           = each.value.target_name
      vnet           = each.value.vnet_name
      resource_group = each.value.rg_name
      subnet_names   = each.value.peer_complete_virtual_networks_enabled ? null : each.value.subnet_names
    }
  }

  providers = {
    azurerm.initiator = azurerm.initiator
    azurerm.target    = azurerm.target
  }
}
