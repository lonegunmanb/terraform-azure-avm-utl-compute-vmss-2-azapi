terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
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

provider "azapi" {}

provider "random" {}

resource "random_integer" "number" {
  min = 1
  max = 100
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-OVMSS-${random_integer.number.result}"
  location = "eastus"
}
