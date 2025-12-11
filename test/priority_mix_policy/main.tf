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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_integer" "test" {
  min = 10000
  max = 99999
}

resource "random_string" "test" {
  length  = 12
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-OVMSS-${random_integer.test.result}"
  location = "eastus2"
}

resource "azurerm_public_ip" "test" {
  name                = "acctpip-${random_integer.test.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn-${random_integer.test.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub-${random_integer.test.result}"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_nat_gateway" "test" {
  name                    = "acctng-${random_integer.test.result}"
  location                = azurerm_resource_group.test.location
  resource_group_name     = azurerm_resource_group.test.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "test" {
  nat_gateway_id       = azurerm_nat_gateway.test.id
  public_ip_address_id = azurerm_public_ip.test.id
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.test.id
  nat_gateway_id = azurerm_nat_gateway.test.id
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-spotPriorityMixVMSS-${random_integer.test.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  priority        = "Spot"
  eviction_policy = "Delete"

  sku_name  = "Standard_D1_v2"
  instances = 3

  tags = {
    "SkipASMAzSecPack"                                                         = "true",
    "platformsettings.host_environment.service.platform_optedin_for_rootcerts" = "true",
    "prevent_deletion_if_contains_resources"                                   = "false"
  }

  platform_fault_domain_count = 2

  os_profile {
    windows_configuration {
      computer_name_prefix = "testvm"
      admin_username       = "myadmin"
      admin_password       = "Passwword1234"

      enable_automatic_updates = true
      provision_vm_agent       = true
      timezone                 = "W. Europe Standard Time"

      winrm_listener {
        protocol = "Http"
      }
    }
  }

  network_interface {
    name    = "TestNetworkProfile-${random_integer.test.result}"
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
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  priority_mix {
    base_regular_count            = 1
    regular_percentage_above_base = 50
  }
}
