terraform {
  required_version = "1.15.7"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.networking.hub.subscription_id
}

provider "azurerm" {
  alias = "vpn"
  features {}
  subscription_id = var.networking.vpn.subscription_id
}
