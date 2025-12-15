resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.number.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  platform_fault_domain_count = 2
  instances                   = 2
  sku_name                    = "Standard_D2s_v3"
  source_image_id             = azurerm_shared_image_version.test.id

  network_interface {
    name    = "orchestrated-nic"
    primary = true
    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.test.id
    }
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    Environment = "env"
    Type        = "Orchestrated"
  }
}
