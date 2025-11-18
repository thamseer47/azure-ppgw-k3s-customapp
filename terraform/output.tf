output "vm_public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}

output "app_gateway_public_ip" {
  value = azurerm_public_ip.appgw_ip.ip_address
}

