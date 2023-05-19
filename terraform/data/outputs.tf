output "resource_group" {
  description = "Resource group of the data group"
  value       = azurerm_resource_group.this
}
output "inputs_storage_account" {
  description = "Storage account"
  value       = azurerm_storage_account.inputs
}
output "processors_storage_account" {
  description = "Storage account for deployments"
  value       = azurerm_storage_account.processors
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_server.this.fqdn
}
output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_server.this.name
}
output "admin_username" {
  description = "Username for the PostgreSQL database admin"
  value       = azurerm_key_vault_secret.db_admin_username.value
}
output "admin_password" {
  description = "Password for the PostgreSQL database admin"
  value       = azurerm_key_vault_secret.db_admin_password.value
}
output "database_names" {
  description = "Database names from PostgreSQL"
  value       = var.database_names
}
