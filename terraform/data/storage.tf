# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${module.common.project_name}-data"
  location = module.common.location
  tags     = local.tags
}

# Create the storage account
resource "azurerm_storage_account" "this" {
  name                     = "sticenetetldata"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# Create the storage container
resource "azurerm_storage_container" "this" {
  name                  = "input"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
