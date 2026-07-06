locals {

  key_vault_resource_group = "sps-platform-${var.subscription}-rg"
  key_vault_subscription   = var.key_vault_subscription

  # Fallback APIM private IP derived from the same supernet CIDR logic used in
  # the apim component. Used when no upstream pipeline output is available (e.g.
  # on a fresh plan before any apply has run).
  sps_infra_supernet = "10.180.0.0/16"
  normalized_env     = var.env == "preview" ? "dev" : var.env == "perftest" ? "test" : var.env == "aat" ? "stg" : var.env
  env_supernet       = cidrsubnet(local.sps_infra_supernet, 6, index(["sbox", "dev", "test", "ithc", "demo", "stg", "prod"], local.normalized_env))
  apim_subnet_cidr   = cidrsubnet(local.env_supernet, 2, 0)
  apim_private_ip    = coalesce(var.apim_private_ip_address, cidrhost(local.apim_subnet_cidr, 4))

  # To be removed once the TLS1.0/1.1 deprecation is complete
  current_ssl_policy = {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20150501"
  }
}
