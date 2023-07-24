# Create the resource group
resource "azurerm_resource_group" "webapps" {
  name     = "rg-${var.project_name}-webapps"
  location = var.location
  tags     = local.tags
}

# Use one of for layer 7:
#   Azure Application Gateway
#   Front Door 

# Azure Load Balancer for layer 4
#resource "azurerm_lb" "example" {
#  name                = "lb-${var.project_name}-webapps"
#  location            = azurerm_resource_group.webapps.location
#  resource_group_name = azurerm_resource_group.webapps.name
#  sku                 = "Standard"
#  sku_tier            = "Regional"
#
#  frontend_ip_configuration {
#    name                 = "PublicIPAddress"
#    public_ip_address_id = var.frontend_ip.id
#  }
#}
