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

resource "random_integer" "test" {
  min = 10000
  max = 99999
}

resource "random_string" "test" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-OVMSS-${random_integer.test.result}"
  location = "eastus"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.test.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  platform_fault_domain_count = 1
  zones                       = ["1"]

  os_profile {}
}
