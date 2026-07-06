locals {
  vnet_rg   = var.resource_group_name
  vnet_name = var.vnet_name

  sps_infra_supernet = "10.180.0.0/16"
  normalized_env     = var.env == "preview" ? "dev" : var.env == "perftest" ? "test" : var.env == "aat" ? "stg" : var.env
  env_supernet       = cidrsubnet(local.sps_infra_supernet, 6, index(["sbox", "dev", "test", "ithc", "demo", "stg", "prod"], local.normalized_env))
  apim_subnet_cidr   = cidrsubnet(local.env_supernet, 2, 0)
}
