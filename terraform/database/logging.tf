# Create the logging rules
resource "azurerm_monitor_diagnostic_setting" "this" {
  name               = "logging-log-analytics"
  target_resource_id = azurerm_postgresql_server.this.id
  log_analytics_workspace_id = var.logging_workspace_id

  log {
    category = "PostgreSQLLogs"
  }

  log {
    category = "QueryStoreRuntimeStatistics"
  }

  log {
    category = "QueryStoreWaitStatistics"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}


