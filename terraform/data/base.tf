# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-data"
  location = var.location
  tags     = local.tags
}
