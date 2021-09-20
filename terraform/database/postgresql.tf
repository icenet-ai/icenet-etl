# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${module.common.project_name}-database"
  location = module.common.location
  tags     = local.tags
}

# Create the PostgreSQL server
resource "azurerm_postgresql_server" "this" {
  name                = "psql-${module.common.project_name}-database"
  location            = module.common.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = join("_", ["GP", "Gen5", var.postgres_cores])

  storage_mb                   = var.storage_mb
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "${azurerm_key_vault_secret.db_admin_username.value}"
  administrator_login_password = "${azurerm_key_vault_secret.db_admin_password.value}"
  version                      = var.postgresql_version
  ssl_enforcement_enabled      = true

  lifecycle {
    ignore_changes = [storage_mb]
  }
  tags = local.tags
}

resource "azurerm_postgresql_database" "this" {
  for_each            = toset(var.database_names)
  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  charset             = "UTF8"
  collation           = "en-GB"
}

resource "azurerm_postgresql_configuration" "this" {
  for_each            = var.postgresql_configurations
  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  value               = each.value
}
