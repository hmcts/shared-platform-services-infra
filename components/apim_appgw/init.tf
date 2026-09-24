terraform {
  required_version = ">= 1.11.1, < 2.0.0"

  backend "azurerm" {
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  subscription_id                 = var.key_vault_subscription
  resource_provider_registrations = "none"
  features {}
  alias = "kv"
}
