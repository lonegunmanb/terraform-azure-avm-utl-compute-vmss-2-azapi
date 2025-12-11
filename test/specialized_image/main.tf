terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "test" {
  length  = 10
  special = false
  upper   = false
}

resource "random_integer" "test" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_integer.test.result}"
  location = "eastus"
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn-${random_integer.test.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "test" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "test" {
  name                = "acctpip-${random_integer.test.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  allocation_method   = "Static"
  domain_name_label   = "acctestvm-${random_string.test.result}"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "testsource" {
  name                = "acctnicsource-${random_integer.test.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "testconfigurationsource"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test.id
  }
}

resource "azurerm_virtual_machine" "testsource" {
  name                  = "testsource"
  location              = azurerm_resource_group.test.location
  resource_group_name   = azurerm_resource_group.test.name
  network_interface_ids = [azurerm_network_interface.testsource.id]
  vm_size               = "Standard_D1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "mdimagetestsource"
    admin_username = "testadmin${random_integer.test.result}"
    admin_password = "Password1234!${random_integer.test.result}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Dev"
    cost-center = "Ops"
  }
}

resource "azurerm_shared_image_gallery" "test" {
  name                = "acctestsig${random_integer.test.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
}

resource "azurerm_shared_image" "test" {
  name                = "acctestimg${random_integer.test.result}"
  gallery_name        = azurerm_shared_image_gallery.test.name
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  os_type             = "Linux"
  specialized         = true

  identifier {
    publisher = "AccTesPublisher${random_integer.test.result}"
    offer     = "AccTesOffer${random_integer.test.result}"
    sku       = "AccTesSku${random_integer.test.result}"
  }
}

resource "azurerm_shared_image_version" "test" {
  name                = "0.0.1"
  gallery_name        = azurerm_shared_image_gallery.test.name
  image_name          = azurerm_shared_image.test.name
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  managed_image_id = azurerm_virtual_machine.testsource.id

  target_region {
    name                   = azurerm_resource_group.test.location
    regional_replica_count = 1
  }

  tags = {
    "foo" = "bar"
  }
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.test.result}"
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
