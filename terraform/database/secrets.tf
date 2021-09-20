# Random string
resource "random_string" "db_admin_password" {
  keepers = {
    resource_group = azurerm_resource_group.this.name
  }
  length  = 25
  special = true
}

# KeyVault secret: PostgreSQL admin name
resource "azurerm_key_vault_secret" "db_admin_username" {
  name         = "${local.db_name}-admin-username"
  value        = "icenetadmin"
  key_vault_id = "${var.key_vault_id}"
  tags         = local.tags
}

# KeyVault secret: PostgreSQL admin password
resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "${local.db_name}-admin-password"
  value        = "${random_string.db_admin_password.result}"
  key_vault_id = "${var.key_vault_id}"
  tags         = local.tags
}