############################################################
# Log Analytics Workspace
############################################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "app-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################################################
# App Gateway Diagnostics → Send logs to LAW
############################################################
resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diag"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
  category = "ApplicationGatewayAccessLog"

  retention_policy {
    enabled = false
  }
}

enabled_log {
  category = "ApplicationGatewayPerformanceLog"

  retention_policy {
    enabled = false
  }
}

enabled_log {
  category = "ApplicationGatewayFirewallLog"

  retention_policy {
    enabled = false
  }
}

metric {
  category = "AllMetrics"

  retention_policy {
    enabled = false
  }
}
