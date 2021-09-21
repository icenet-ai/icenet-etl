output "logging_workspace_id" {
  description = "ID of the Azure log analytics workspace"
  value       = azurerm_log_analytics_workspace.this.id
}
