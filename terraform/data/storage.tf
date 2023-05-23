# Create the storage account
resource "azurerm_storage_account" "inputs" {
  name                     = "st${var.project_name}data"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# Create the storage container
resource "azurerm_storage_container" "inputs" {
  name                  = "input"
  storage_account_name  = azurerm_storage_account.inputs.name
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "inputs_rules" {
  storage_account_id         = azurerm_storage_account.inputs.id

  default_action             = "Allow"

  virtual_network_subnet_ids = [var.public_subnet_id]
  bypass                     = ["None"]
}

# Create the storage account
resource "azurerm_storage_account" "processors" {
  name                     = "st${var.project_name}proc"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# Storage container for deploying functions
resource "azurerm_storage_container" "processors" {
  name                       = "processors"
  storage_account_name       = azurerm_storage_account.processors.name
  container_access_type      = "private"
}

resource "azurerm_storage_account_network_rules" "processors_rules" {
  storage_account_id = azurerm_storage_account.processors.id

  default_action             = "Allow"
  ip_rules                   = []
  virtual_network_subnet_ids = [var.private_subnet_id]
  bypass                     = []
}
