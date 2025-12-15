resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.number.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  sku_name  = "Standard_F2"
  instances = 1

  platform_fault_domain_count = 2

  os_profile {
    custom_data = "Y3VzdG9tIGRhdGEh"

    linux_configuration {
      computer_name_prefix = "prefix"
      admin_username       = "ubuntu"

      admin_ssh_key {
        username   = "ubuntu"
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqzSi9IHoYnbE3YQ+B2fQEVT8iGFemyPovpEtPziIVB hello@world.com"
      }
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

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
