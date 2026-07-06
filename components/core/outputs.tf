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

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vnet_name" {
  value = module.networking.vnet_names["vnet"]
}
