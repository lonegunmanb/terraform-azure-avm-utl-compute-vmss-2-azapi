resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                        = "acctestVMSS-${random_string.name.result}"
  location                    = azurerm_resource_group.test.location
  resource_group_name         = azurerm_resource_group.test.name
  platform_fault_domain_count = 1
  zones                       = ["1"]

  network_interface {
    name    = "TestNetworkProfile"
    primary = true

    ip_configuration {
      name      = "TestIPConfiguration"
      primary   = true
      subnet_id = azurerm_subnet.test.id
    }
  }

  os_profile {
    linux_configuration {
      admin_username                  = "testadmin"
      admin_password                  = "Password1234!"
      disable_password_authentication = false
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  data_disk {
    lun                  = 0
    caching              = "ReadWrite"
    storage_account_type = "Premium_ZRS"
    disk_size_gb         = 10
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
