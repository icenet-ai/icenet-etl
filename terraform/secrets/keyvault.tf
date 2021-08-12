# Load common module
module "common" {
  source = "../common"
}

# Create the secrets resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${module.common.project_name}-secrets"
  location = module.common.location
  tags     = module.common.tags
}

# Create the secrets keyvault
resource "azurerm_key_vault" "this" {
  name                = "kv-${module.common.project_name}-secrets"
  location            = module.common.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id
  tags                = module.common.tags
}

# Set the KeyVault permissions
resource "azurerm_key_vault_access_policy" "allow_group" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.developers_group_id
  key_permissions = [
    "create",
    "delete",
    "get",
    "list",
  ]
  secret_permissions = [
    "set",
    "delete",
    "get",
    "list",
  ]
}