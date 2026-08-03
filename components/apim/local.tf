locals {
  vnet_rg   = coalesce(var.resource_group_name, "rg-${var.product}-${var.env}")
  vnet_name = coalesce(var.vnet_name, "${var.product}-networking-vnet-${var.env}")

  sps_infra_supernet = "10.180.0.0/16"
  normalized_env     = var.env == "preview" ? "dev" : var.env == "perftest" ? "test" : var.env == "aat" ? "stg" : var.env
  env_supernet       = cidrsubnet(local.sps_infra_supernet, 6, index(["sbox", "dev", "test", "ithc", "demo", "stg", "prod"], local.normalized_env))
  apim_subnet_cidr   = cidrsubnet(local.env_supernet, 2, 0)
}
