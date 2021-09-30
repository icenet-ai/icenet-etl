terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "=1.14.0"
    }
  }
}

provider "postgresql" {
  host            = azurerm_postgresql_server.this.fqdn
  port            = 5432
  database        = var.database_names[0]
  username        = "${azurerm_key_vault_secret.db_admin_username.value}@${azurerm_postgresql_server.this.fqdn}"
  password        = azurerm_key_vault_secret.db_admin_password.value
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}
