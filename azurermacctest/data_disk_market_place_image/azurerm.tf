resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.number.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  sku_name  = "Standard_F2"
  instances = 1

  platform_fault_domain_count = 2

  os_profile {

    linux_configuration {
      computer_name_prefix = "testvm-test"
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

      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.test.id]
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  data_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 900
    create_option        = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "micro-focus"
    offer     = "arcsight-logger"
    sku       = "arcsight_logger_72_byol"
    version   = "7.2.0"
  }

  plan {
    name      = "arcsight_logger_72_byol"
    product   = "arcsight-logger"
    publisher = "micro-focus"
  }
}
