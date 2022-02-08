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
