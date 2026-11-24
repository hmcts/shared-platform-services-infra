mock_provider "azurerm" {
  mock_data "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/certificates"
    }
  }

  mock_data "azurerm_key_vault_secret" {
    defaults = {
      value = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azurerm_key_vault_certificate" {
    defaults = {
      secret_id = "https://certificates.vault.azure.net/secrets/wildcard/123456"
      version   = "123456"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-sps-platform-sbox/providers/Microsoft.ManagedIdentity/userAssignedIdentities/sps-api-mgmt-sbox-token-translation"
      client_id    = "00000000-0000-0000-0000-000000000003"
      principal_id = "00000000-0000-0000-0000-000000000004"
    }
  }
}

mock_provider "azurerm" {
  alias = "central-app-kv"

  mock_data "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/central-app-reg"
    }
  }
}

mock_provider "azapi" {}

override_module {
  target = module.api-mgmt
  outputs = {
    name = "sps-api-mgmt-sbox"
    id   = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-sps-platform-sbox/providers/Microsoft.ApiManagement/service/sps-api-mgmt-sbox"
  }
}

override_module {
  target = module.ctags
  outputs = {
    common_tags = { environment = "sbox", product = "sps-platform" }
  }
}

variables {
  env          = "sbox"
  subscription = "sbox"
  product      = "sps-platform"
  project      = "spshmcts"
  builtFrom    = "https://github.com/hmcts/shared-platform-services-infra"
  location     = "uksouth"
}

run "identity_disabled_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_user_assigned_identity.token_translation) == 0
    error_message = "No token-translation identity should be created by default."
  }

  assert {
    condition     = output.apim_token_translation_identity_id == null && output.apim_token_translation_identity_client_id == null && output.apim_token_translation_identity_principal_id == null
    error_message = "Disabled identity outputs must be null."
  }
}

run "sandbox_identity_enabled" {
  command = apply

  variables {
    apim_token_translation_identity_enabled = true
  }

  assert {
    condition     = length(azurerm_user_assigned_identity.token_translation) == 1 && azurerm_user_assigned_identity.token_translation[0].name == "sps-api-mgmt-sbox-token-translation" && azurerm_user_assigned_identity.token_translation[0].resource_group_name == "rg-sps-platform-sbox"
    error_message = "Create exactly one dedicated identity in the sandbox APIM resource group."
  }

  assert {
    condition     = azurerm_user_assigned_identity.token_translation[0].location == "uksouth" && azurerm_user_assigned_identity.token_translation[0].tags == tomap({ environment = "sbox", product = "sps-platform" })
    error_message = "The identity must reuse the APIM location and common tags."
  }

  assert {
    condition     = output.apim_token_translation_identity_id == azurerm_user_assigned_identity.token_translation[0].id && output.apim_token_translation_identity_client_id == "00000000-0000-0000-0000-000000000003" && output.apim_token_translation_identity_principal_id == "00000000-0000-0000-0000-000000000004"
    error_message = "Expose the correct resource, client and principal IDs for the federation handoff."
  }
}

run "non_sandbox_identity_disabled" {
  command = apply

  variables {
    env          = "dev"
    subscription = "dev"
  }

  assert {
    condition     = length(azurerm_user_assigned_identity.token_translation) == 0 && output.apim_token_translation_identity_id == null
    error_message = "Non-sandbox environments must remain unchanged with the default flag."
  }
}
