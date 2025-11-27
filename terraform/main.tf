##############################
# Resource Groups
##############################

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

##############################
# EXISTING RESOURCES (IMPORTED)
# DO NOT CREATE AGAIN
##############################

# resource "azurerm_virtual_network" "vnet" {
#   ...
# }

# resource "azurerm_subnet" "subnet_appgw" { ... }
# resource "azurerm_subnet" "subnet_vm" { ... }

# resource "azurerm_public_ip" "vm_ip" { ... }
# resource "azurerm_public_ip" "appgw_ip" { ... }

##############################
# Network Interface for VM
##############################

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

##############################
# Linux VM
##############################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-k3s"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  size                = "Standard_B1s"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_username = var.vm_admin

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

##############################
# Application Gateway v2 + WAF
##############################

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

  backend_address_pool {
    name         = "backendpool"
    ip_addresses = [azurerm_public_ip.vm_ip.ip_address]
  }

  backend_http_settings {
    name          = "http-settings"
    port          = 30080
    protocol      = "Http"
    request_timeout = 30
    probe_name    = "k3s-probe"
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
}
