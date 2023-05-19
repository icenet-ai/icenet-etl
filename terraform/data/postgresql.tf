# Create the PostgreSQL server
resource "azurerm_postgresql_server" "this" {
  name                = "psql-${var.project_name}-database"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = join("_", ["GP", "Gen5", var.postgres_cores])

  storage_mb                   = var.storage_mb
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true
  public_network_access_enabled = false

  administrator_login              = azurerm_key_vault_secret.db_admin_username.value
  administrator_login_password     = azurerm_key_vault_secret.db_admin_password.value
  version                          = var.postgresql_version
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

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

resource "azurerm_private_endpoint" "this" {
  name                = "psql-${var.project_name}-endpoint"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = var.public_subnet

  private_service_connection {
    name                           = "psql-${var.project_name}-pvtsvcconn"
    private_connection_resource_id = azurerm_postgresql_server.this.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}