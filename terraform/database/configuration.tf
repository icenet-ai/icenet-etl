# Install the PostGIS extension
resource "postgresql_extension" "postgis" {
  name       = "postgis"
  depends_on = [azurerm_postgresql_database.this]
}

# Role names
resource "postgresql_role" "reader" {
  name             = azurerm_key_vault_secret.db_reader_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_reader_password.value
  connection_limit = 4
  depends_on       = [azurerm_postgresql_database.this]
}
resource "postgresql_role" "writer" {
  name             = azurerm_key_vault_secret.db_writer_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_writer_password.value
  connection_limit = 4
  depends_on       = [azurerm_postgresql_database.this]
}

# Role privileges
resource "postgresql_grant" "read_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.reader.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["SELECT"]
  depends_on  = [azurerm_postgresql_database.this]
}
resource "postgresql_grant" "write_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.writer.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["UPDATE", "INSERT", "DELETE"]
  depends_on  = [azurerm_postgresql_database.this]
}
