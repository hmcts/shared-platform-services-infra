# shared-platform-services-infra

Infrastructure-as-code for the Shared Platform Services (SPS) Azure environment,
managed with Terraform and deployed via Azure DevOps.

## Repository structure

| Path | Purpose |
|---|---|
| `components/` | Terraform components deployed per environment (core, apim, apim_appgw) |
| `environments/` | Per-environment `.tfvars` files |
| `modules/` | Shared local Terraform modules |
| `portal/` | APIM developer portal artifacts, scripts, and documentation |
| `azure-pipeline.yaml` | Azure DevOps pipeline definition |

## Developer portal

APIM developer portal customizations (pages, layouts, styles, media) are managed
separately from the Terraform infrastructure. See [`portal/README.md`](portal/README.md)
for full documentation including:

- How to export portal customizations from a live APIM instance
- Where artifacts are stored and how to commit them
- CI/CD deployment flow (post-APIM Terraform stage)
- Required permissions
- Environment-specific configuration
- Rollback guidance

## Deployment pipeline

Auto-generated from `azure-pipeline.yaml` — shows every `<environment>_<component>` stage and its
dependencies (same-environment component order, plus the environment's `Precheck`/promotion gate).

<!-- BEGIN_PIPELINE_DIAGRAM -->
```mermaid
flowchart LR
  Precheck
  subgraph sbox ["sbox"]
    sbox_core["core"]
    sbox_apim["apim"]
    sbox_core --> sbox_apim
    sbox_apim_appgw["apim_appgw"]
    sbox_apim --> sbox_apim_appgw
  end
  Precheck --> sbox_core
  subgraph dev ["dev"]
    dev_core["core"]
    dev_apim["apim"]
    dev_core --> dev_apim
    dev_apim_appgw["apim_appgw"]
    dev_apim --> dev_apim_appgw
  end
  Precheck --> dev_core
  subgraph test ["test"]
    test_core["core"]
    test_apim["apim"]
    test_core --> test_apim
    test_apim_appgw["apim_appgw"]
    test_apim --> test_apim_appgw
  end
  Precheck --> test_core
  subgraph ithc ["ithc"]
    ithc_core["core"]
    ithc_apim["apim"]
    ithc_core --> ithc_apim
    ithc_apim_appgw["apim_appgw"]
    ithc_apim --> ithc_apim_appgw
  end
  Precheck --> ithc_core
  subgraph demo ["demo"]
    demo_core["core"]
    demo_apim["apim"]
    demo_core --> demo_apim
    demo_apim_appgw["apim_appgw"]
    demo_apim --> demo_apim_appgw
  end
  Precheck --> demo_core
  subgraph stg ["stg"]
    stg_core["core"]
    stg_apim["apim"]
    stg_core --> stg_apim
    stg_apim_appgw["apim_appgw"]
    stg_apim --> stg_apim_appgw
  end
  Precheck --> stg_core
  subgraph prod ["prod"]
    prod_core["core"]
    prod_apim["apim"]
    prod_core --> prod_apim
    prod_apim_appgw["apim_appgw"]
    prod_apim --> prod_apim_appgw
  end
  Precheck --> prod_core
```
<!-- END_PIPELINE_DIAGRAM -->

<!-- BEGIN_TF_DOCS -->
### `core`

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.15.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.6 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_azurerm.central-app-kv"></a> [azurerm.central-app-kv](#provider\_azurerm.central-app-kv) | 4.80.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cross_tenant_peering"></a> [cross\_tenant\_peering](#module\_cross\_tenant\_peering) | ../../modules/cross-tenant-peering | n/a |
| <a name="module_ctags"></a> [ctags](#module\_ctags) | github.com/hmcts/terraform-module-common-tags | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | github.com/hmcts/terraform-module-azure-virtual-networking | 4.x |
| <a name="module_vnet_peer_hub"></a> [vnet\_peer\_hub](#module\_vnet\_peer\_hub) | github.com/hmcts/terraform-module-vnet-peering | master |
| <a name="module_vnet_peer_vpn"></a> [vnet\_peer\_vpn](#module\_vnet\_peer\_vpn) | github.com/hmcts/terraform-module-vnet-peering | master |

### Resources

| Name | Type |
|------|------|
| [azurerm_dev_test_global_vm_shutdown_schedule.debug_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/dev_test_global_vm_shutdown_schedule) | resource |
| [azurerm_key_vault.extid](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault) | resource |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault) | resource |
| [azurerm_linux_virtual_machine.debug_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.debug_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_resource_group.extid](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.debug_vm_admin_login](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.private_dns_vnet_join](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rbac](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.api_state_store](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_container.api_state_container](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_container) | resource |
| [azurerm_virtual_machine_extension.debug_vm_aad_login](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [tls_private_key.debug_vm](https://registry.terraform.io/providers/hashicorp/tls/4.0.6/docs/resources/private_key) | resource |
| [azuread_group.api_marketplace](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.central_app_registration](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.multi_tenant_client_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.multi_tenant_client_secret](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subscription) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_routes_apim"></a> [additional\_routes\_apim](#input\_additional\_routes\_apim) | A list of additional routes configurations | <pre>list(object({<br/>    name                   = string<br/>    address_prefix         = string<br/>    next_hop_type          = string<br/>    next_hop_in_ip_address = string<br/>  }))</pre> | `[]` | no |
| <a name="input_apim_appgw_backend_pool_fqdns"></a> [apim\_appgw\_backend\_pool\_fqdns](#input\_apim\_appgw\_backend\_pool\_fqdns) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_backend_pool_ips"></a> [apim\_appgw\_backend\_pool\_ips](#input\_apim\_appgw\_backend\_pool\_ips) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_exclusions"></a> [apim\_appgw\_exclusions](#input\_apim\_appgw\_exclusions) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_max_capacity"></a> [apim\_appgw\_max\_capacity](#input\_apim\_appgw\_max\_capacity) | n/a | `number` | `10` | no |
| <a name="input_apim_appgw_min_capacity"></a> [apim\_appgw\_min\_capacity](#input\_apim\_appgw\_min\_capacity) | n/a | `number` | `2` | no |
| <a name="input_apim_custom_nsg_rules"></a> [apim\_custom\_nsg\_rules](#input\_apim\_custom\_nsg\_rules) | A map of custom NSG rules to apply in addition to the default rules to the APIM NSG | <pre>map(object({<br/>    priority                     = number<br/>    direction                    = string<br/>    access                       = string<br/>    protocol                     = string<br/>    source_port_range            = optional(string)<br/>    source_port_ranges           = optional(list(string))<br/>    destination_port_range       = optional(string)<br/>    destination_port_ranges      = optional(list(string))<br/>    source_address_prefix        = optional(string)<br/>    source_address_prefixes      = optional(list(string))<br/>    destination_address_prefix   = optional(string)<br/>    destination_address_prefixes = optional(list(string))<br/>    description                  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_apim_diagnostic_settings"></a> [apim\_diagnostic\_settings](#input\_apim\_diagnostic\_settings) | Configuration for the APIM Application Insights diagnostic settings | <pre>object({<br/>    sampling_percentage          = optional(number, 100)<br/>    always_log_errors            = optional(bool, true)<br/>    http_correlation_protocol    = optional(string, "W3C")<br/>    verbosity                    = optional(string, "information")<br/>    frontend_request_body_bytes  = optional(number, 0)<br/>    frontend_response_body_bytes = optional(number, 0)<br/>    backend_request_body_bytes   = optional(number, 0)<br/>    backend_response_body_bytes  = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_apim_sku_name"></a> [apim\_sku\_name](#input\_apim\_sku\_name) | n/a | `string` | `"Developer"` | no |
| <a name="input_apim_subscription_managers"></a> [apim\_subscription\_managers](#input\_apim\_subscription\_managers) | Managed identities granted the custom APIM subscription manager role (list/get/create/delete subscription keys) on the APIM instance. Key is a logical name, value is the identity's principal (object) ID. | `map(string)` | `{}` | no |
| <a name="input_autoShutdown"></a> [autoShutdown](#input\_autoShutdown) | n/a | `bool` | `false` | no |
| <a name="input_builtFrom"></a> [builtFrom](#input\_builtFrom) | n/a | `string` | n/a | yes |
| <a name="input_cross_tenant_peering"></a> [cross\_tenant\_peering](#input\_cross\_tenant\_peering) | Configuration for cross-tenant VNet peering providers and peering targets. | <pre>object({<br/>    # The CNP (hmcts) subscription that contains the SPS VNet to peer from<br/>    cnp_subscription_id = optional(string, "bd2864ed-4f3e-45ed-9c6a-8d179674bab1")<br/>    # The CPP non-live subscription that contains the target VNet to peer to<br/>    cpp_subscription_id = optional(string, "e6b5053b-4c38-4475-a835-a025aeb3d8c7")<br/>    # Map of VNet peerings to create — key is a logical name used as the Terraform resource key<br/>    peerings = optional(map(object({<br/>      source_name = string # Name of the peering link on the CNP/SPS side<br/>      target_name = string # Name of the peering link on the CPP side<br/>      vnet_name   = string # Name of the target VNet in the CPP subscription<br/>      rg_name     = string # Resource group of the target VNet in the CPP subscription<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_debug_vm"></a> [debug\_vm](#input\_debug\_vm) | Configuration for a temporary Ubuntu VM deployed into the private-endpoints subnet, for troubleshooting cross-tenant/cross-network connectivity. Not deployed by default — set enabled = true per-environment in tfvars. `image` defaults to Ubuntu 26.04 LTS — confirm the offer/sku are still current for the target region (e.g. `az vm image list --publisher Canonical --all --output table`) before relying on the defaults in a new environment. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    size    = optional(string, "Standard_D2ds_v5")<br/>    image = optional(object({<br/>      publisher = optional(string, "Canonical")<br/>      offer     = optional(string, "ubuntu-26_04-lts")<br/>      sku       = optional(string, "server")<br/>      version   = optional(string, "latest")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_department"></a> [department](#input\_department) | n/a | `string` | `"sps"` | no |
| <a name="input_deploy_extid_rg"></a> [deploy\_extid\_rg](#input\_deploy\_extid\_rg) | Whether to deploy the external identity resource group | `bool` | `false` | no |
| <a name="input_destinations"></a> [destinations](#input\_destinations) | Declared to satisfy the shared tfvars file; not used directly in components | `map` | `{}` | no |
| <a name="input_developer_portal"></a> [developer\_portal](#input\_developer\_portal) | Configuration for the APIM developer portal custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_developers_group"></a> [developers\_group](#input\_developers\_group) | The name of the Azure AD group that will be granted access over infra. | `string` | `"DTS AMp Developers"` | no |
| <a name="input_disable_trusted_service_connectivity"></a> [disable\_trusted\_service\_connectivity](#input\_disable\_trusted\_service\_connectivity) | Disable Trusted Service Connectivity for APIM | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_expiresAfter"></a> [expiresAfter](#input\_expiresAfter) | Date when Sandbox resources can be deleted. Format: YYYY-MM-DD | `string` | `"3000-01-01"` | no |
| <a name="input_frontends"></a> [frontends](#input\_frontends) | n/a | `map` | `{}` | no |
| <a name="input_gateway_hostname"></a> [gateway\_hostname](#input\_gateway\_hostname) | Configuration for the APIM gateway custom domain and certificate | <pre>object({<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_hub_app_gw_private_ip_address"></a> [hub\_app\_gw\_private\_ip\_address](#input\_hub\_app\_gw\_private\_ip\_address) | n/a | `list` | `[]` | no |
| <a name="input_identity_provider"></a> [identity\_provider](#input\_identity\_provider) | Configuration for the APIM identity provider | <pre>object({<br/>    app_id_secret_name     = optional(string, "api-marketplace-apim-nonprod-app-id")<br/>    app_secret_secret_name = optional(string, "api-marketplace-apim-nonprod-secret")<br/>  })</pre> | `{}` | no |
| <a name="input_key_vault_subscription"></a> [key\_vault\_subscription](#input\_key\_vault\_subscription) | n/a | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"UK South"` | no |
| <a name="input_management"></a> [management](#input\_management) | Configuration for the APIM management custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_networking"></a> [networking](#input\_networking) | Networking configuration for the virtual network. | <pre>object({<br/>    hub = optional(object({<br/>      next_hop_ip         = optional(string, "10.11.72.36")<br/>      subscription_id     = optional(string, "fb084706-583f-4c9a-bdab-949aac66ba5c")<br/>      vnet_name           = optional(string, "hmcts-hub-nonprodi")<br/>      resource_group_name = optional(string, "hmcts-hub-nonprodi")<br/>    }))<br/>    vpn = optional(object({<br/>      subscription_id     = optional(string, "ed302caf-ec27-4c64-a05e-85731c3ce90e")<br/>      vnet_name           = optional(string, "mgmt-vpn-2-vnet")<br/>      resource_group_name = optional(string, "mgmt-vpn-2-mgmt")<br/>    }))<br/>  })</pre> | <pre>{<br/>  "hub": {},<br/>  "vpn": {}<br/>}</pre> | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | n/a | `string` | `""` | no |
| <a name="input_product"></a> [product](#input\_product) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `any` | n/a | yes |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | The email address of the APIM publisher. | `string` | `"DTSPlatformOperations@justice.gov.uk"` | no |
| <a name="input_send_access_logs_to_log_analytics"></a> [send\_access\_logs\_to\_log\_analytics](#input\_send\_access\_logs\_to\_log\_analytics) | Whether to send access logs to log analytics workspace | `bool` | `false` | no |
| <a name="input_ssl_mode"></a> [ssl\_mode](#input\_ssl\_mode) | n/a | `string` | `"FrontDoor"` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | n/a | `any` | `null` | no |
| <a name="input_subscription"></a> [subscription](#input\_subscription) | n/a | `any` | n/a | yes |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | n/a | `string` | `"Detection"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | n/a |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | n/a |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | n/a |

### `apim`

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.1, < 2.0.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_azurerm.central-app-kv"></a> [azurerm.central-app-kv](#provider\_azurerm.central-app-kv) | 4.80.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api-mgmt"></a> [api-mgmt](#module\_api-mgmt) | git::https://github.com/hmcts/cnp-module-api-mgmt-private.git | change/top_level_domain |
| <a name="module_ctags"></a> [ctags](#module\_ctags) | git::https://github.com/hmcts/terraform-module-common-tags.git | master |

### Resources

| Name | Type |
|------|------|
| [azurerm_api_management_identity_provider_aad.entra_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/api_management_identity_provider_aad) | resource |
| [azurerm_api_management_named_value.environment](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/api_management_named_value) | resource |
| [azurerm_role_assignment.apim_subscription_manager](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.apim_subscription_manager](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_definition) | resource |
| [azurerm_key_vault.central_app_registration](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_certificate.certificate](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_certificate) | data source |
| [azurerm_key_vault_certificate.portal](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_certificate) | data source |
| [azurerm_key_vault_secret.base64_cpp_intermediate_ca](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.base64_cpp_root_ca](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.entra_id_app_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.entra_id_app_secret](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.entra_id_tenant_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_routes_apim"></a> [additional\_routes\_apim](#input\_additional\_routes\_apim) | A list of additional routes configurations | <pre>list(object({<br/>    name                   = string<br/>    address_prefix         = string<br/>    next_hop_type          = string<br/>    next_hop_in_ip_address = string<br/>  }))</pre> | `[]` | no |
| <a name="input_apim_appgw_backend_pool_fqdns"></a> [apim\_appgw\_backend\_pool\_fqdns](#input\_apim\_appgw\_backend\_pool\_fqdns) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_backend_pool_ips"></a> [apim\_appgw\_backend\_pool\_ips](#input\_apim\_appgw\_backend\_pool\_ips) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_exclusions"></a> [apim\_appgw\_exclusions](#input\_apim\_appgw\_exclusions) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_max_capacity"></a> [apim\_appgw\_max\_capacity](#input\_apim\_appgw\_max\_capacity) | n/a | `number` | `10` | no |
| <a name="input_apim_appgw_min_capacity"></a> [apim\_appgw\_min\_capacity](#input\_apim\_appgw\_min\_capacity) | n/a | `number` | `2` | no |
| <a name="input_apim_custom_nsg_rules"></a> [apim\_custom\_nsg\_rules](#input\_apim\_custom\_nsg\_rules) | A map of custom NSG rules to apply in addition to the default rules to the APIM NSG | <pre>map(object({<br/>    priority                     = number<br/>    direction                    = string<br/>    access                       = string<br/>    protocol                     = string<br/>    source_port_range            = optional(string)<br/>    source_port_ranges           = optional(list(string))<br/>    destination_port_range       = optional(string)<br/>    destination_port_ranges      = optional(list(string))<br/>    source_address_prefix        = optional(string)<br/>    source_address_prefixes      = optional(list(string))<br/>    destination_address_prefix   = optional(string)<br/>    destination_address_prefixes = optional(list(string))<br/>    description                  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_apim_diagnostic_settings"></a> [apim\_diagnostic\_settings](#input\_apim\_diagnostic\_settings) | Configuration for the APIM Application Insights diagnostic settings | <pre>object({<br/>    sampling_percentage          = optional(number, 100)<br/>    always_log_errors            = optional(bool, true)<br/>    http_correlation_protocol    = optional(string, "W3C")<br/>    verbosity                    = optional(string, "information")<br/>    frontend_request_body_bytes  = optional(number, 0)<br/>    frontend_response_body_bytes = optional(number, 0)<br/>    backend_request_body_bytes   = optional(number, 0)<br/>    backend_response_body_bytes  = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_apim_sku_name"></a> [apim\_sku\_name](#input\_apim\_sku\_name) | n/a | `string` | `"Developer"` | no |
| <a name="input_apim_subscription_managers"></a> [apim\_subscription\_managers](#input\_apim\_subscription\_managers) | Managed identities granted the custom APIM subscription manager role (list/get/create/delete subscription keys) on the APIM instance. Key is a logical name, value is the identity's principal (object) ID. | `map(string)` | `{}` | no |
| <a name="input_autoShutdown"></a> [autoShutdown](#input\_autoShutdown) | n/a | `bool` | `false` | no |
| <a name="input_builtFrom"></a> [builtFrom](#input\_builtFrom) | n/a | `string` | n/a | yes |
| <a name="input_cross_tenant_peering"></a> [cross\_tenant\_peering](#input\_cross\_tenant\_peering) | Configuration for cross-tenant VNet peering providers and peering targets. | <pre>object({<br/>    # The CNP (hmcts) subscription that contains the SPS VNet to peer from<br/>    cnp_subscription_id = optional(string, "bd2864ed-4f3e-45ed-9c6a-8d179674bab1")<br/>    # The CPP non-live subscription that contains the target VNet to peer to<br/>    cpp_subscription_id = optional(string, "e6b5053b-4c38-4475-a835-a025aeb3d8c7")<br/>    # Map of VNet peerings to create — key is a logical name used as the Terraform resource key<br/>    peerings = optional(map(object({<br/>      source_name = string # Name of the peering link on the CNP/SPS side<br/>      target_name = string # Name of the peering link on the CPP side<br/>      vnet_name   = string # Name of the target VNet in the CPP subscription<br/>      rg_name     = string # Resource group of the target VNet in the CPP subscription<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_debug_vm"></a> [debug\_vm](#input\_debug\_vm) | Configuration for a temporary Ubuntu VM deployed into the private-endpoints subnet, for troubleshooting cross-tenant/cross-network connectivity. Not deployed by default — set enabled = true per-environment in tfvars. `image` defaults to Ubuntu 26.04 LTS — confirm the offer/sku are still current for the target region (e.g. `az vm image list --publisher Canonical --all --output table`) before relying on the defaults in a new environment. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    size    = optional(string, "Standard_D2ds_v5")<br/>    image = optional(object({<br/>      publisher = optional(string, "Canonical")<br/>      offer     = optional(string, "ubuntu-26_04-lts")<br/>      sku       = optional(string, "server")<br/>      version   = optional(string, "latest")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_department"></a> [department](#input\_department) | n/a | `string` | `"sps"` | no |
| <a name="input_deploy_extid_rg"></a> [deploy\_extid\_rg](#input\_deploy\_extid\_rg) | Whether to deploy the external identity resource group | `bool` | `false` | no |
| <a name="input_destinations"></a> [destinations](#input\_destinations) | Declared to satisfy the shared tfvars file; not used directly in components | `map` | `{}` | no |
| <a name="input_developer_portal"></a> [developer\_portal](#input\_developer\_portal) | Configuration for the APIM developer portal custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_developers_group"></a> [developers\_group](#input\_developers\_group) | The name of the Azure AD group that will be granted access over infra. | `string` | `"DTS AMp Developers"` | no |
| <a name="input_disable_trusted_service_connectivity"></a> [disable\_trusted\_service\_connectivity](#input\_disable\_trusted\_service\_connectivity) | Disable Trusted Service Connectivity for APIM | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_expiresAfter"></a> [expiresAfter](#input\_expiresAfter) | Date when Sandbox resources can be deleted. Format: YYYY-MM-DD | `string` | `"3000-01-01"` | no |
| <a name="input_frontends"></a> [frontends](#input\_frontends) | n/a | `map` | `{}` | no |
| <a name="input_gateway_hostname"></a> [gateway\_hostname](#input\_gateway\_hostname) | Configuration for the APIM gateway custom domain and certificate | <pre>object({<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_hub_app_gw_private_ip_address"></a> [hub\_app\_gw\_private\_ip\_address](#input\_hub\_app\_gw\_private\_ip\_address) | n/a | `list` | `[]` | no |
| <a name="input_identity_provider"></a> [identity\_provider](#input\_identity\_provider) | Configuration for the APIM identity provider | <pre>object({<br/>    app_id_secret_name     = optional(string, "api-marketplace-apim-nonprod-app-id")<br/>    app_secret_secret_name = optional(string, "api-marketplace-apim-nonprod-secret")<br/>  })</pre> | `{}` | no |
| <a name="input_key_vault_subscription"></a> [key\_vault\_subscription](#input\_key\_vault\_subscription) | n/a | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"UK South"` | no |
| <a name="input_management"></a> [management](#input\_management) | Configuration for the APIM management custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_networking"></a> [networking](#input\_networking) | Networking configuration for the virtual network. | <pre>object({<br/>    hub = optional(object({<br/>      next_hop_ip         = optional(string, "10.11.72.36")<br/>      subscription_id     = optional(string, "fb084706-583f-4c9a-bdab-949aac66ba5c")<br/>      vnet_name           = optional(string, "hmcts-hub-nonprodi")<br/>      resource_group_name = optional(string, "hmcts-hub-nonprodi")<br/>    }))<br/>    vpn = optional(object({<br/>      subscription_id     = optional(string, "ed302caf-ec27-4c64-a05e-85731c3ce90e")<br/>      vnet_name           = optional(string, "mgmt-vpn-2-vnet")<br/>      resource_group_name = optional(string, "mgmt-vpn-2-mgmt")<br/>    }))<br/>  })</pre> | <pre>{<br/>  "hub": {},<br/>  "vpn": {}<br/>}</pre> | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | n/a | `string` | `""` | no |
| <a name="input_product"></a> [product](#input\_product) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `any` | n/a | yes |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | The email address of the APIM publisher. | `string` | `"DTSPlatformOperations@justice.gov.uk"` | no |
| <a name="input_send_access_logs_to_log_analytics"></a> [send\_access\_logs\_to\_log\_analytics](#input\_send\_access\_logs\_to\_log\_analytics) | Whether to send access logs to log analytics workspace | `bool` | `false` | no |
| <a name="input_ssl_mode"></a> [ssl\_mode](#input\_ssl\_mode) | n/a | `string` | `"FrontDoor"` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | n/a | `any` | `null` | no |
| <a name="input_subscription"></a> [subscription](#input\_subscription) | n/a | `any` | n/a | yes |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | n/a | `string` | `"Detection"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_apim_name"></a> [apim\_name](#output\_apim\_name) | The name of the APIM service. Used by the portal deployment pipeline stage. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group containing the APIM service. Used by the portal deployment pipeline stage. |

### `apim_appgw`

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.1, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app-gw"></a> [app-gw](#module\_app-gw) | git::https://github.com/hmcts/terraform-module-apim-application-gateway.git | DTSPO-31984-waf-changes |
| <a name="module_ctags"></a> [ctags](#module\_ctags) | git::https://github.com/hmcts/terraform-module-common-tags.git | master |
| <a name="module_logworkspace"></a> [logworkspace](#module\_logworkspace) | git::https://github.com/hmcts/terraform-module-log-analytics-workspace-id.git | master |

### Resources

| Name | Type |
|------|------|
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subscription) | data source |
| [external_external.bash_script](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_routes_apim"></a> [additional\_routes\_apim](#input\_additional\_routes\_apim) | A list of additional routes configurations | <pre>list(object({<br/>    name                   = string<br/>    address_prefix         = string<br/>    next_hop_type          = string<br/>    next_hop_in_ip_address = string<br/>  }))</pre> | `[]` | no |
| <a name="input_apim_appgw_backend_pool_fqdns"></a> [apim\_appgw\_backend\_pool\_fqdns](#input\_apim\_appgw\_backend\_pool\_fqdns) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_backend_pool_ips"></a> [apim\_appgw\_backend\_pool\_ips](#input\_apim\_appgw\_backend\_pool\_ips) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_exclusions"></a> [apim\_appgw\_exclusions](#input\_apim\_appgw\_exclusions) | n/a | `list` | `[]` | no |
| <a name="input_apim_appgw_max_capacity"></a> [apim\_appgw\_max\_capacity](#input\_apim\_appgw\_max\_capacity) | n/a | `number` | `10` | no |
| <a name="input_apim_appgw_min_capacity"></a> [apim\_appgw\_min\_capacity](#input\_apim\_appgw\_min\_capacity) | n/a | `number` | `2` | no |
| <a name="input_apim_custom_nsg_rules"></a> [apim\_custom\_nsg\_rules](#input\_apim\_custom\_nsg\_rules) | A map of custom NSG rules to apply in addition to the default rules to the APIM NSG | <pre>map(object({<br/>    priority                     = number<br/>    direction                    = string<br/>    access                       = string<br/>    protocol                     = string<br/>    source_port_range            = optional(string)<br/>    source_port_ranges           = optional(list(string))<br/>    destination_port_range       = optional(string)<br/>    destination_port_ranges      = optional(list(string))<br/>    source_address_prefix        = optional(string)<br/>    source_address_prefixes      = optional(list(string))<br/>    destination_address_prefix   = optional(string)<br/>    destination_address_prefixes = optional(list(string))<br/>    description                  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_apim_diagnostic_settings"></a> [apim\_diagnostic\_settings](#input\_apim\_diagnostic\_settings) | Configuration for the APIM Application Insights diagnostic settings | <pre>object({<br/>    sampling_percentage          = optional(number, 100)<br/>    always_log_errors            = optional(bool, true)<br/>    http_correlation_protocol    = optional(string, "W3C")<br/>    verbosity                    = optional(string, "information")<br/>    frontend_request_body_bytes  = optional(number, 0)<br/>    frontend_response_body_bytes = optional(number, 0)<br/>    backend_request_body_bytes   = optional(number, 0)<br/>    backend_response_body_bytes  = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_apim_sku_name"></a> [apim\_sku\_name](#input\_apim\_sku\_name) | n/a | `string` | `"Developer"` | no |
| <a name="input_apim_subscription_managers"></a> [apim\_subscription\_managers](#input\_apim\_subscription\_managers) | Managed identities granted the custom APIM subscription manager role (list/get/create/delete subscription keys) on the APIM instance. Key is a logical name, value is the identity's principal (object) ID. | `map(string)` | `{}` | no |
| <a name="input_autoShutdown"></a> [autoShutdown](#input\_autoShutdown) | n/a | `bool` | `false` | no |
| <a name="input_builtFrom"></a> [builtFrom](#input\_builtFrom) | n/a | `string` | n/a | yes |
| <a name="input_cross_tenant_peering"></a> [cross\_tenant\_peering](#input\_cross\_tenant\_peering) | Configuration for cross-tenant VNet peering providers and peering targets. | <pre>object({<br/>    # The CNP (hmcts) subscription that contains the SPS VNet to peer from<br/>    cnp_subscription_id = optional(string, "bd2864ed-4f3e-45ed-9c6a-8d179674bab1")<br/>    # The CPP non-live subscription that contains the target VNet to peer to<br/>    cpp_subscription_id = optional(string, "e6b5053b-4c38-4475-a835-a025aeb3d8c7")<br/>    # Map of VNet peerings to create — key is a logical name used as the Terraform resource key<br/>    peerings = optional(map(object({<br/>      source_name = string # Name of the peering link on the CNP/SPS side<br/>      target_name = string # Name of the peering link on the CPP side<br/>      vnet_name   = string # Name of the target VNet in the CPP subscription<br/>      rg_name     = string # Resource group of the target VNet in the CPP subscription<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_debug_vm"></a> [debug\_vm](#input\_debug\_vm) | Configuration for a temporary Ubuntu VM deployed into the private-endpoints subnet, for troubleshooting cross-tenant/cross-network connectivity. Not deployed by default — set enabled = true per-environment in tfvars. `image` defaults to Ubuntu 26.04 LTS — confirm the offer/sku are still current for the target region (e.g. `az vm image list --publisher Canonical --all --output table`) before relying on the defaults in a new environment. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    size    = optional(string, "Standard_D2ds_v5")<br/>    image = optional(object({<br/>      publisher = optional(string, "Canonical")<br/>      offer     = optional(string, "ubuntu-26_04-lts")<br/>      sku       = optional(string, "server")<br/>      version   = optional(string, "latest")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_department"></a> [department](#input\_department) | n/a | `string` | `"sps"` | no |
| <a name="input_deploy_extid_rg"></a> [deploy\_extid\_rg](#input\_deploy\_extid\_rg) | Whether to deploy the external identity resource group | `bool` | `false` | no |
| <a name="input_destinations"></a> [destinations](#input\_destinations) | Declared to satisfy the shared tfvars file; not used directly in components | `map` | `{}` | no |
| <a name="input_developer_portal"></a> [developer\_portal](#input\_developer\_portal) | Configuration for the APIM developer portal custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_developers_group"></a> [developers\_group](#input\_developers\_group) | The name of the Azure AD group that will be granted access over infra. | `string` | `"DTS AMp Developers"` | no |
| <a name="input_disable_trusted_service_connectivity"></a> [disable\_trusted\_service\_connectivity](#input\_disable\_trusted\_service\_connectivity) | Disable Trusted Service Connectivity for APIM | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_expiresAfter"></a> [expiresAfter](#input\_expiresAfter) | Date when Sandbox resources can be deleted. Format: YYYY-MM-DD | `string` | `"3000-01-01"` | no |
| <a name="input_frontends"></a> [frontends](#input\_frontends) | n/a | `map` | `{}` | no |
| <a name="input_gateway_hostname"></a> [gateway\_hostname](#input\_gateway\_hostname) | Configuration for the APIM gateway custom domain and certificate | <pre>object({<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_hub_app_gw_private_ip_address"></a> [hub\_app\_gw\_private\_ip\_address](#input\_hub\_app\_gw\_private\_ip\_address) | n/a | `list` | `[]` | no |
| <a name="input_identity_provider"></a> [identity\_provider](#input\_identity\_provider) | Configuration for the APIM identity provider | <pre>object({<br/>    app_id_secret_name     = optional(string, "api-marketplace-apim-nonprod-app-id")<br/>    app_secret_secret_name = optional(string, "api-marketplace-apim-nonprod-secret")<br/>  })</pre> | `{}` | no |
| <a name="input_key_vault_subscription"></a> [key\_vault\_subscription](#input\_key\_vault\_subscription) | n/a | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"UK South"` | no |
| <a name="input_management"></a> [management](#input\_management) | Configuration for the APIM management custom domain and certificate | <pre>object({<br/>    custom_domain_name = optional(string)<br/>    key_vault_id       = optional(string)<br/>    cert_name          = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_networking"></a> [networking](#input\_networking) | Networking configuration for the virtual network. | <pre>object({<br/>    hub = optional(object({<br/>      next_hop_ip         = optional(string, "10.11.72.36")<br/>      subscription_id     = optional(string, "fb084706-583f-4c9a-bdab-949aac66ba5c")<br/>      vnet_name           = optional(string, "hmcts-hub-nonprodi")<br/>      resource_group_name = optional(string, "hmcts-hub-nonprodi")<br/>    }))<br/>    vpn = optional(object({<br/>      subscription_id     = optional(string, "ed302caf-ec27-4c64-a05e-85731c3ce90e")<br/>      vnet_name           = optional(string, "mgmt-vpn-2-vnet")<br/>      resource_group_name = optional(string, "mgmt-vpn-2-mgmt")<br/>    }))<br/>  })</pre> | <pre>{<br/>  "hub": {},<br/>  "vpn": {}<br/>}</pre> | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | n/a | `string` | `""` | no |
| <a name="input_product"></a> [product](#input\_product) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `any` | n/a | yes |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | The email address of the APIM publisher. | `string` | `"DTSPlatformOperations@justice.gov.uk"` | no |
| <a name="input_send_access_logs_to_log_analytics"></a> [send\_access\_logs\_to\_log\_analytics](#input\_send\_access\_logs\_to\_log\_analytics) | Whether to send access logs to log analytics workspace | `bool` | `false` | no |
| <a name="input_ssl_mode"></a> [ssl\_mode](#input\_ssl\_mode) | n/a | `string` | `"FrontDoor"` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | n/a | `any` | `null` | no |
| <a name="input_subscription"></a> [subscription](#input\_subscription) | n/a | `any` | n/a | yes |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | n/a | `string` | `"Detection"` | no |

### Outputs

No outputs.

<!-- END_TF_DOCS -->
