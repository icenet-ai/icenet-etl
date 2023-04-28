# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-secrets"
  location = var.location
  tags     = local.tags
}

# Create the KeyVault
resource "azurerm_key_vault" "this" {
  name                = "kv-${var.project_name}-secrets"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id
  tags                = local.tags
}

# Set the KeyVault permissions for the developers group
#resource "azurerm_key_vault_access_policy" "allow_group" {
#  key_vault_id       = azurerm_key_vault.this.id
#  tenant_id          = var.tenant_id
#  object_id          = var.developers_group_id
#  key_permissions    = var.key_permissions
#  secret_permissions = var.secret_permissions
#}

# Set the KeyVault permissions for the current user
data "azuread_client_config" "current" {}
resource "azurerm_key_vault_access_policy" "allow_user" {
  key_vault_id       = azurerm_key_vault.this.id
  tenant_id          = var.tenant_id
  object_id          = data.azuread_client_config.current.object_id
  key_permissions    = var.key_permissions
  secret_permissions = var.secret_permissions
}
