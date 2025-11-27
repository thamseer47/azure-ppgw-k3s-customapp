locals {
  prefix = var.project_prefix
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

#####################
# Resource Groups
#####################
resource "azurerm_resource_group" "network" {
  name     = "${local.prefix}-rg-network"
  location = var.location
}

resource "azurerm_resource_group" "app" {
  name     = "${local.prefix}-rg-app"
  location = var.location
}

resource "azurerm_resource_group" "appgw" {
  name     = "${local.prefix}-rg-appgw"
  location = var.location
}

#####################
# VNet + Subnets
#####################
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix}-vnet"
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

#####################
# NSG for VM (SSH allowed)
#####################
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${local.prefix}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.app.name
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "vm_assn" {
  subnet_id                 = azurerm_subnet.subnet_vm.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

#####################
# Public IP + NIC + VM (with cloud-init)
#####################
resource "azurerm_public_ip" "vm_ip" {
  name                = "${local.prefix}-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

# Cloud-init script will install k3s and create manifests (see file below)
data "template_file" "cloud_init" {
  template = file("${path.module}/scripts/cloud-init-k3s.yaml.tpl")

  vars = {
    nodeport = var.nodeport
    admin    = var.vm_admin
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.prefix}-vm-k3s"
  resource_group_name = azurerm_resource_group.app.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.vm_admin
    public_key = file(var.ssh_pub_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # supply cloud-init
  custom_data = base64encode(data.template_file.cloud_init.rendered)
  tags = {
    project = local.prefix
  }
}

#####################
# Public IP for App Gateway + App Gateway
#####################
resource "azurerm_public_ip" "appgw_ip" {
  name                = "${local.prefix}-appgw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${local.prefix}-appgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
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
    # public IP of VM (App Gateway probes/routing to VM public IP:NodePort)
    ip_addresses = [azurerm_public_ip.vm_ip.ip_address]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = var.nodeport
    protocol              = "Http"
    request_timeout       = 30
    # Either host or pick_host_xxx must be set. Use host = VM public IP (works when backend is IP)
    host = azurerm_public_ip.vm_ip.ip_address
    probe_name = "k3s-probe"
  }

  probe {
    name                = "k3s-probe"
    protocol            = "Http"
    path                = "/"
    port                = var.nodeport
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = azurerm_public_ip.vm_ip.ip_address
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
    azurerm_public_ip.appgw_ip,
    azurerm_linux_virtual_machine.vm
  ]
}

#####################
# Outputs
#####################
output "vm_public_ip" {
  description = "Public IP of VM"
  value       = azurerm_public_ip.vm_ip.ip_address
}

output "appgw_public_ip" {
  description = "Public IP of App Gateway"
  value       = azurerm_public_ip.appgw_ip.ip_address
}
