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

  public_network_access_enabled = true

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

resource "azurerm_private_endpoint" "database" {
  name                = "pvt-${var.project_name}-database"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name              = "pvt-${var.project_name}-database"
    is_manual_connection = "false"
    private_connection_resource_id = azurerm_postgresql_server.this.id
    subresource_names = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone.id]
  }
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

resource "azurerm_postgresql_firewall_rule" "user_rules" {
  for_each            = { for name, cidr_block in var.allowed_cidrs : name => cidr_block }
  name                = "AllowConnectionsFrom${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = cidrhost(each.value, 0)
  end_ip_address      = cidrhost(each.value, -1)
}

resource "azurerm_postgresql_firewall_rule" "azure_rules" {
  name                = "AllowConnectionsFromAzure"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

### Configuration using cyrilgdn/postgresql

# Install the PostGIS extension
resource "postgresql_extension" "postgis" {
  name       = "postgis"
  depends_on = [azurerm_postgresql_server.this]
}

# Role names
resource "postgresql_role" "reader" {
  name             = azurerm_key_vault_secret.db_reader_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_reader_password.value
  connection_limit = 50
  depends_on       = [azurerm_postgresql_server.this]
}
resource "postgresql_role" "writer" {
  name             = azurerm_key_vault_secret.db_writer_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_writer_password.value
  connection_limit = 4
  depends_on       = [azurerm_postgresql_server.this]
}

# Role privileges
resource "postgresql_default_privileges" "read_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.reader.name
  schema      = "public"
  owner       = azurerm_key_vault_secret.db_admin_username.value
  object_type = "table"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.reader]
}
resource "postgresql_default_privileges" "write_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.writer.name
  schema      = "public"
  owner       = azurerm_key_vault_secret.db_admin_username.value
  object_type = "table"
  privileges  = ["DELETE", "INSERT", "SELECT", "UPDATE"]
  depends_on  = [postgresql_role.writer]
}
