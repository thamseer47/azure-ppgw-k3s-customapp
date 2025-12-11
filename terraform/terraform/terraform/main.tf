############################################################
#  Use Existing Resource Group
############################################################
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

############################################################
#  Local Names
############################################################
locals {
  vnet_name      = "${var.prefix}-vnet"
  subnet_name    = "${var.prefix}-subnet"
  nsg_name       = "${var.prefix}-nsg"
  public_ip_name = "${var.prefix}-pip"
  nic_name       = "${var.prefix}-nic"
  vm_name        = "vm-${var.prefix}"
}

############################################################
#  Virtual Network
############################################################
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
}

############################################################
#  Subnet
############################################################
resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

############################################################
#  Network Security Group
############################################################
resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.allowed_node_ports
    content {
      name                       = "Allow-NodePort-${security_rule.value}"
      priority                   = 200 + security_rule.value % 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value)
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

############################################################
#  NSG ↔ Subnet Association  (Required)
############################################################
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

############################################################
#  Public IP
############################################################
resource "azurerm_public_ip" "pip" {
  name                = local.public_ip_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

############################################################
#  Network Interface
############################################################
resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = {
    created_by = "terraform"
  }
}

############################################################
#  Virtual Machine
############################################################
resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.vm_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  tags = {
    created_by = "terraform"
  }
}
############################################################
#  NSG ↔ Subnet Association  (Required for Terraform import)
############################################################
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
