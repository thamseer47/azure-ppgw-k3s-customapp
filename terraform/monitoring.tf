############################################################
# Log Analytics Workspace
############################################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_app_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################################################
# App Gateway Diagnostics
############################################################
resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diag"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "ApplicationGatewayAccessLog"
    enabled  = true
  }

  log {
    category = "ApplicationGatewayPerformanceLog"
    enabled  = true
  }

  log {
    category = "ApplicationGatewayFirewallLog"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
