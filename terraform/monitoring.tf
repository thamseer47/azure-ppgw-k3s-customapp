############################################################
# Variables required by monitoring.tf
############################################################

variable "prefix" {
  description = "Prefix for naming diagnostic settings"
  default     = "app"
}

############################################################
# Log Analytics Workspace (IMPORTED RESOURCE)
# COMMENT OUT if workspace already exists
############################################################

# resource "azurerm_log_analytics_workspace" "law" {
#   name                = "app-law"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.app.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

############################################################
# Diagnostic Settings for Application Gateway
############################################################

resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "${var.prefix}-appgw-diag"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

