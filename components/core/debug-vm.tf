# Temporary troubleshooting VM.
#
# Deployed into the private-endpoints subnet so it sits behind the same route
# table and NSG as private-endpoint traffic, and can be used to test
# reachability across the hub, VPN and cross-tenant CPP peerings (see
# cross-tenant-peering.tf) from inside the SPS platform VNet. Off by default —
# enable with `debug_vm = { enabled = true }` in the relevant environment tfvars.
#
# Login is via Azure AD (`az ssh vm`), through the AADSSHLoginForLinux
# extension, scoped to the group in var.developers_group — there are no
# SSH keys to distribute. The key pair below only exists to satisfy the VM
# create API and is never used to authenticate.

resource "tls_private_key" "debug_vm" {
  count     = var.debug_vm.enabled ? 1 : 0
  algorithm = "ED25519"
}

resource "azurerm_network_interface" "debug_vm" {
  count               = var.debug_vm.enabled ? 1 : 0
  name                = "nic-debug-${local.naming_env}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.networking.subnet_ids["vnet-private-endpoints"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = module.ctags.common_tags
}

resource "azurerm_linux_virtual_machine" "debug_vm" {
  count               = var.debug_vm.enabled ? 1 : 0
  name                = "vm-debug-${local.naming_env}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  size                = var.debug_vm.size
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.debug_vm[0].id]

  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.debug_vm[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.debug_vm.image.publisher
    offer     = var.debug_vm.image.offer
    sku       = var.debug_vm.image.sku
    version   = var.debug_vm.image.version
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}

  tags = merge(module.ctags.common_tags, {
    purpose = "cross-tenant-connectivity-troubleshooting"
  })
}

resource "azurerm_virtual_machine_extension" "debug_vm_aad_login" {
  count                      = var.debug_vm.enabled ? 1 : 0
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.debug_vm[0].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

# Lets members of var.developers_group sudo in via `az ssh vm` without
# needing any of the platform team's own credentials.
resource "azurerm_role_assignment" "debug_vm_admin_login" {
  count                = var.debug_vm.enabled ? 1 : 0
  scope                = azurerm_linux_virtual_machine.debug_vm[0].id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azuread_group.api_marketplace.object_id
}

# Reuses the existing autoShutdown switch (see sbox.tfvars) so this box
# doesn't run — and cost — 24/7 once someone forgets about it.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "debug_vm" {
  count              = var.debug_vm.enabled && var.autoShutdown ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.debug_vm[0].id
  location           = azurerm_resource_group.this.location
  enabled            = true

  daily_recurrence_time = "1900"
  timezone              = "GMT Standard Time"

  notification_settings {
    enabled = false
  }
}
