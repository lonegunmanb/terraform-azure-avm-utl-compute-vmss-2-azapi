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
  min = 1
  max = 99999
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-OVMSS-${random_integer.test.result}"
  location = "eastus"
}

resource "azurerm_virtual_network" "test" {
  name                = "acctestvn-${random_integer.test.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "test" {
  name                 = "acctestsn-${random_integer.test.result}"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "test" {
  name                = "acctestpip-${random_integer.test.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "test" {
  name                = "acctestlb-${random_integer.test.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  sku = "Standard"

  frontend_ip_configuration {
    name                 = "ip-address"
    public_ip_address_id = azurerm_public_ip.test.id
  }
}

resource "azurerm_lb_backend_address_pool" "test" {
  name            = "acctestbap-${random_integer.test.result}"
  loadbalancer_id = azurerm_lb.test.id
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.test.result}"
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
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDvXYZAjVUt2aojUV3XIA+PY6gXrgbvktXwf2NoIHGlQFhogpMEyOfqgogCtTBM7MNCS3ELul6SV+mlpH08Ki45ADIQuDXdommCvsMFW096JrsHOJpGfjCsJ1gbbv7brB3Ag+BSGb4qO3pRsEVTtZCeJDwfH5D7vmqP5xXcELKR4UAtKQKUhLvt6mhW90sFLTJeOTiYGbavIKqfCUFSeSMQkUPr8o3uzOfeWyCw7tc7szLuvfwJ5poGHuve73KKAlUnDTPUrhyj7iITZSDl+/i+bpDzPyCyJWDMsC0ON7q2fDr2mEz0L9ACrsI5Nx3lt5fe+IaHSrjivqnL8SqUWSN45o9Qp99sGWFiuTfos8f1jp+AXzC4ArVtKyRg/CnzKRiK0CGSxBJ5s9zAoa7yBBmjCszq89vFa0eMgpEIZFwa6kKJKt9AfRBXgO9YGPV4uaN7topy92/p2pE+vF8IafarbvnTDOQt62mS07tXYqYg1DhecrmBVWKlq9oafBweoeTjoq52SoGsuDc/YAOzIgWVIuvV8yKoh9KbXPWowjLtxDhRIS/d1nMMNdNI8X0TQivgi5+umMgAXhsVAKSNDUauLt4jimYkWAuE+R6KoCqVFdaB9bQDySBjAziruDSe3reToydjzzluvHMjWK8QiDynxs41pi4zZz6gAlca3QPkEQ== hello@world.com"
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
