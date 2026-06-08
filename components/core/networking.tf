locals {
  sps-infra-supernet    = "10.180.0.0/16"
  env                   = var.env == "preview" ? "dev" : var.env == "perftest" ? "test" : var.env == "aat" ? "stg" : var.env
  env-specific-supernet = cidrsubnet(local.sps-infra-supernet, 6, index(["sbox", "dev", "test", "ithc", "demo", "stg", "prod"], local.env))
}

module "networking" {
  source = "github.com/hmcts/terraform-module-azure-virtual-networking?ref=4.x"

  env         = local.naming_env
  product     = var.product
  common_tags = module.ctags.common_tags
  component   = "networking"

  existing_resource_group_name = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location

  vnets = {
    vnet = {
      address_space = [local.env-specific-supernet]
      subnets = {
        # Subnet 0 — API Management
        # Azure minimum subnet size: /27. A /24 is derived here to provide
        # headroom across multiple APIM units. No delegation required.
        # name_override is required: cnp-module-api-mgmt-private hardcodes
        # the subnet lookup name as "api-management".
        api-management = {
          address_prefixes = [cidrsubnet(local.env-specific-supernet, 2, 0)]
          name_override    = "api-management"
        }
        # Subnet 1 — Application Gateway v2 / WAF
        # Azure hard requirement: /24 minimum for Application Gateway v2 with WAF.
        # No delegation required.
        app-gateway = {
          address_prefixes = [cidrsubnet(local.env-specific-supernet, 2, 1)]
        }
        # Subnet 2 — Private Endpoints
        private-endpoints = {
          address_prefixes = [cidrsubnet(local.env-specific-supernet, 2, 2)]
        }
      }
    }
  }

  route_tables = {
    rt = {
      subnets = ["vnet-api-management", "vnet-private-endpoints"]
      routes = {
        default = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = var.networking.hub.next_hop_ip
        }
      }
    }
    appgw-rt = {
      subnets = ["vnet-app-gateway"]
      routes = {
        RFC_1918_A = {
          address_prefix         = "10.0.0.0/8"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = var.networking.hub.next_hop_ip
        }
        RFC_1918_B = {
          address_prefix         = "172.16.0.0/12"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = var.networking.hub.next_hop_ip
        }
        RFC_1918_C = {
          address_prefix         = "192.168.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = var.networking.hub.next_hop_ip
        }
      }
    }
  }

  network_security_groups = {
    nsg = {
      subnets = ["vnet-api-management", "vnet-private-endpoints"]
      rules = {
        "allow_intra_subnet" = {
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        }
      }
    }
  }
}

module "vnet_peer_hub" {
  source = "github.com/hmcts/terraform-module-vnet-peering?ref=master"
  peerings = {
    source = {
      name           = "${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}-to-hub"
      vnet_id        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${module.networking.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${module.networking.vnet_names["vnet"]}"
      vnet           = module.networking.vnet_names["vnet"]
      resource_group = module.networking.resource_group_name
    }
    target = {
      name           = "hub-to-${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}"
      vnet           = var.networking.hub.vnet_name
      resource_group = var.networking.hub.resource_group_name
    }
  }

  providers = {
    azurerm.initiator = azurerm
    azurerm.target    = azurerm.hub
  }

  depends_on = [module.networking]
}

moved {
  from = module.vnet_peer_vpn.azurerm_virtual_network_peering.initiator_to_target
  to   = module.vnet_peer_vpn[0].azurerm_virtual_network_peering.initiator_to_target
}

moved {
  from = module.vnet_peer_vpn.azurerm_virtual_network_peering.target_to_initiator
  to   = module.vnet_peer_vpn[0].azurerm_virtual_network_peering.target_to_initiator
}

module "vnet_peer_vpn" {
  source = "github.com/hmcts/terraform-module-vnet-peering?ref=master"
  count  = local.naming_env == "perftest" ? 0 : 1
  peerings = {
    source = {
      name           = "${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}-to-vpn"
      vnet_id        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${module.networking.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${module.networking.vnet_names["vnet"]}"
      vnet           = module.networking.vnet_names["vnet"]
      resource_group = module.networking.resource_group_name
    }
    target = {
      name           = "vpn-to-${module.networking.vnet_names["vnet"]}-vnet-${local.naming_env}"
      vnet           = var.networking.vpn.vnet_name
      resource_group = var.networking.vpn.resource_group_name
    }
  }

  providers = {
    azurerm.initiator = azurerm
    azurerm.target    = azurerm.vpn
  }

  depends_on = [module.networking]
}
