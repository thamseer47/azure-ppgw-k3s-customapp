##########################################
# Provider
##########################################
terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}


##########################################
# Resource Groups
##########################################

resource "azurerm_resource_group" "network" {
  name     = "rg-network"
  location = var.location
}

resource "azurerm_resource_group" "app" {
  name     = "rg-app"
  location = var.location
}

resource "azurerm_resource_group" "appgw" {
  name     = "rg-appgw"
  location = var.location
}

##########################################
# Virtual Network + Subnets
##########################################

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

##########################################
# Public IP for VM
##########################################

resource "azurerm_public_ip" "vm_ip" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.app.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

##########################################
# Network Interface for VM
##########################################

resource "azurerm_network_interface" "nic" {
  name                = "nic-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  ip_configuration {
    name                          = "vm-ipconfig"
    subnet_id                     = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

##########################################
# Linux VM (Ubuntu 22.04)
##########################################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-k3s"
  resource_group_name = azurerm_resource_group.app.name
  location            = var.location
  size                = "Standard_B1s"

  admin_username = var.vm_admin

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.vm_admin
    public_key = file(var.ssh_key_path)
  }

  os_disk {
    name                 = "osdisk-k3s"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

##########################################
# Public IP for Application Gateway
##########################################

resource "azurerm_public_ip" "appgw_ip" {
  name                = "appgw-public-ip"
  resource_group_name = azurerm_resource_group.appgw.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

##########################################
# Application Gateway (WAF_v2)
##########################################

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-k3s"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.subnet_appgw.id
  }

  frontend_port {
    name = "port80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  ####################################
  # Backend: VM Private IP (correct)
  ####################################
  backend_address_pool {
    name         = "backendpool"
    ip_addresses = [azurerm_network_interface.nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "http-settings"
    port                  = 30080
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = "k3s-probe"
  }

  probe {
    name                = "k3s-probe"
    protocol            = "Http"
    path                = "/"
    port                = 30080
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "backendpool"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}
