# Create the resource group
resource "azurerm_resource_group" "webapps" {
  name     = "rg-${var.project_name}-webapps"
  location = var.location
  tags     = local.tags
}
