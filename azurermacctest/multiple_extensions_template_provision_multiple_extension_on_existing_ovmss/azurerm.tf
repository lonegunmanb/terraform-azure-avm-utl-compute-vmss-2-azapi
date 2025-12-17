resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.number.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  sku_name = "Standard_D1_v2"

  # Orchestrated VMSS allocation will timeout at service side due to extension, set instances to 0 to avoid the timeout
  instances = 0

  platform_fault_domain_count = 2

  os_profile {
    linux_configuration {
      computer_name_prefix = "testvm-${random_integer.number.result}"
      admin_username       = "myadmin"
      admin_password       = "Passwword1234"

      disable_password_authentication = false
    }
  }

  network_interface {
    name    = "TestNetworkProfile"
    primary = true

    ip_configuration {
      name      = "TestIPConfiguration"
      primary   = true
      subnet_id = azurerm_subnet.test.id

      public_ip_address {
        name                    = "TestPublicIPConfiguration"
        domain_name_label       = "test-domain-label"
        idle_timeout_in_minutes = 4
      }
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  extension {
    name                               = "CustomScript"
    publisher                          = "Microsoft.Azure.Extensions"
    type                               = "CustomScript"
    type_handler_version               = "2.0"
    auto_upgrade_minor_version_enabled = true

    settings = jsonencode({
      "commandToExecute" = "echo $HOSTNAME"
    })

    protected_settings = jsonencode({
      "managedIdentity" = {}
    })
  }

  extension {
    name                                      = "Docker"
    publisher                                 = "Microsoft.Azure.Extensions"
    type                                      = "DockerExtension"
    type_handler_version                      = "1.0"
    auto_upgrade_minor_version_enabled        = true
    extensions_to_provision_after_vm_creation = ["CustomScript"]
  }
}
