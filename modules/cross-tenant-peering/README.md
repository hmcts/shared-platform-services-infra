# cross-tenant-peering module

Generic cross-tenant VNet peering wrapper around the maintained module:

- `github.com/hmcts/terraform-module-vnet-peering`

This module supports both:

- Full VNet peering (`peer_complete_virtual_networks_enabled = true`, default)
- Subnet peering (`peer_complete_virtual_networks_enabled = false`)

The caller decides environment/region gating and provider identities.

## Provider requirements

The module expects two caller-supplied azurerm provider aliases:

- `azurerm.initiator`
- `azurerm.target`

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | -------- |
| source_vnet_name | Name of the source/initiator VNet | string | n/a | Yes |
| source_resource_group | Resource group of the source/initiator VNet | string | n/a | Yes |
| source_subnet_names | Source subnet names used when subnet peering is enabled | list(string) | `[]` | No |
| peerings | Peering definitions keyed by name | map(object) | `{}` | No |

`peerings` object shape:

| Field | Type | Required | Default | Notes |
| ----- | ---- | -------- | ------- | ----- |
| vnet_name | string | Yes | n/a | Target VNet name |
| rg_name | string | Yes | n/a | Target resource group |
| source_name | string | Yes | n/a | Initiator peering name |
| target_name | string | Yes | n/a | Target peering name |
| subnet_names | list(string) | No | `[]` | Used only when subnet peering is enabled |
| peer_complete_virtual_networks_enabled | bool | No | `true` | `false` enables subnet peering mode |

## Behavior

- Iterates each item in `peerings` and creates one peering pair.
- When `peer_complete_virtual_networks_enabled = true`:
  - Subnet lists are set to `null`.
- When `peer_complete_virtual_networks_enabled = false`:
  - Source uses `source_subnet_names`.
  - Target uses `each.value.subnet_names`.

## Usage

### Full VNet peering example

```hcl
module "cross_tenant_peering_full_vnet" {
  source = "../modules/cross-tenant-peering"

  providers = {
    azurerm.initiator = azurerm.ProviderA
    azurerm.target    = azurerm.ProviderB
  }

  source_vnet_name      = "sourceVnetName"
  source_resource_group = "sourceResourceGroupName"

  peerings = {
    "sourceVNetName" = {
      source_name                            = "source-to-target"
      target_name                            = "target-to-source"
      vnet_name                              = "targetVNetName"
      rg_name                                = "targetResourceGroupName"
    }
  }
}
```

### Subnet peering example

```hcl
module "cross_tenant_peering_subnet" {
  source = "../modules/cross-tenant-peering"

  providers = {
    azurerm.initiator = azurerm.ProviderA
    azurerm.target    = azurerm.ProviderB
  }

  source_vnet_name      = "sourceVnetName"
  source_resource_group = "sourceResourceGroupName"
  source_subnet_names   = ["sourceSubnetName1"]

  peerings = {
    "sourceVNetName" = {
      peer_complete_virtual_networks_enabled = false
      source_name                            = "source-to-target"
      target_name                            = "target-to-source"
      vnet_name                              = "targetVNetName"
      rg_name                                = "targetResourceGroupName"
      subnet_names                           = ["targetSubnetName1", "targetSubnetName2"]
    }
  }
}
```

## Integration note

Real world example can be found in [components/hub_core/30-nonlive-cross-tenant-peering.tf](../../hub_core/30-nonlive-cross-tenant-peering.tf), where:

- env/region gating is applied with `count`
- cross-tenant credentials and subscription IDs are loaded from Key Vault
- provider aliases are passed as `azurerm.initiator` / `azurerm.target`
