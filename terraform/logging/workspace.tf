# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${module.common.project_name}-logging"
  location = module.common.location
  tags     = local.tags
}

# Create the log analytics workspace
resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${module.common.project_name}-logging"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
