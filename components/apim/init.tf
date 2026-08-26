terraform {
  required_version = ">= 1.11.1, < 2.0.0"

  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.80.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "central-app-kv"
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "6c4d2513-a873-41b4-afdd-b05a33206631" # Central App Registration subscription
}
