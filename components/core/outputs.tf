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

# Consumed by the DNS repository to create A records. The IP is only assigned once the CPP side approves the connection.
output "cpp_private_endpoint_ips" {
  value = {
    for k, pe in azurerm_private_endpoint.cpp : k => try(pe.private_service_connection[0].private_ip_address, null)
  }
}
