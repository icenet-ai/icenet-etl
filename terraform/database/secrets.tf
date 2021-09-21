# Random strings
resource "random_string" "db_admin_password" {
  keepers = {
    resource_group = azurerm_resource_group.this.name
  }
  length  = 25
  special = true
}
resource "random_string" "db_reader_password" {
  keepers = {
    resource_group = azurerm_resource_group.this.name
  }
  length  = 25
  special = true
}
resource "random_string" "db_writer_password" {
  keepers = {
    resource_group = azurerm_resource_group.this.name
  }
  length  = 25
  special = true
}


# KeyVault secrets: PostgreSQL admin
resource "azurerm_key_vault_secret" "db_admin_username" {
  name         = "${local.db_name}-admin-username"
  value        = "icenetadmin"
  key_vault_id = var.key_vault_id
  tags         = local.tags
}
resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "${local.db_name}-admin-password"
  value        = random_string.db_admin_password.result
  key_vault_id = var.key_vault_id
  tags         = local.tags
}

# KeyVault secrets: PostgreSQL reader
resource "azurerm_key_vault_secret" "db_reader_username" {
  name         = "${local.db_name}-reader-username"
  value        = "icenetreader"
  key_vault_id = var.key_vault_id
  tags         = local.tags
}
resource "azurerm_key_vault_secret" "db_reader_password" {
  name         = "${local.db_name}-reader-password"
  value        = random_string.db_reader_password.result
  key_vault_id = var.key_vault_id
  tags         = local.tags
}

# KeyVault secrets: PostgreSQL writer
resource "azurerm_key_vault_secret" "db_writer_username" {
  name         = "${local.db_name}-writer-username"
  value        = "icenetwriter"
  key_vault_id = var.key_vault_id
  tags         = local.tags
}
resource "azurerm_key_vault_secret" "db_writer_password" {
  name         = "${local.db_name}-writer-password"
  value        = random_string.db_writer_password.result
  key_vault_id = var.key_vault_id
  tags         = local.tags
}