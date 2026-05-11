output "resource_group" {
  value = {
    name = azurerm_resource_group.this.name
    id   = azurerm_resource_group.this.id
  }
}

output "vnet_id" {
  value = module.networking.vnet_ids["vnet"]
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}
