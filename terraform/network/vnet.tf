resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-network"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "rg-${var.project_name}-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags     = local.tags

  # Class B
  # 172.16.0.0/14 - 172.16.0.1 - 172.19.255.254
  address_space       = ["172.16.0.0/16"]
}

# TODO: Gateway subnet for resources to access public 172.16.0.0/20

# Resources that can be access from public internet
resource "azurerm_subnet" "public" {
  name           = "sub-${var.project_name}-public"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes     = ["172.16.16.0/20"]
  service_endpoints = ["Microsoft.Storage"]
}

# Resources not accessible from the internet
resource "azurerm_subnet" "private" {
  name                 = "sub-${var.project_name}-private"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes     = ["172.16.128.0/20"]
  service_endpoints = ["Microsoft.Storage"]
}
