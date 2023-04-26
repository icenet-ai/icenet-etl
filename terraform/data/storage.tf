# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-data"
  location = var.location
  tags     = local.tags
}

# Create the storage account
resource "azurerm_storage_account" "this" {
  name                     = "st${var.project_name}data"
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

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_name     = azurerm_storage_account.this.name
  resource_group_name      = azurerm_resource_group.this.name

  default_action             = "Allow"
  ip_rules                   = []
  virtual_network_subnet_ids = [var.subnet]
  bypass                     = []
}
