# Role names
resource "postgresql_role" "reader" {
  name             = azurerm_key_vault_secret.db_reader_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_reader_password.value
  connection_limit = 4
}
resource "postgresql_role" "writer" {
  name             = azurerm_key_vault_secret.db_writer_username.value
  login            = true
  password         = azurerm_key_vault_secret.db_writer_password.value
  connection_limit = 4
}

# Role privileges
resource "postgresql_grant" "read_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.reader.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}
resource "postgresql_grant" "write_tables" {
  database    = var.database_names[0]
  role        = postgresql_role.writer.name
  schema      = "public"
  object_type = "table"
  privileges  = ["UPDATE", "INSERT", "DELETE"]
}
