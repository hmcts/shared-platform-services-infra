output "apim_name" {
  description = "The name of the APIM service. Used by the portal deployment pipeline stage."
  value       = module.api-mgmt.name
}

output "resource_group_name" {
  description = "The resource group containing the APIM service. Used by the portal deployment pipeline stage."
  value       = local.vnet_rg
}
