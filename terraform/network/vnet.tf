resource "azurerm_resource_group" "this" {
  name      = "rg-${var.project_name}-network"
  location  = var.location
  tags      = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                  = "rg-${var.project_name}-network"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  tags                  = local.tags

  # Class B
  # 172.16.0.0/14 - 172.16.0.1 - 172.19.255.254
  address_space = ["172.16.0.0/16"]
}

# Resources that can be accessed from the public internet
resource "azurerm_subnet" "gateway" {
  name                  = "sub-${var.project_name}-gateway"
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_name  = azurerm_virtual_network.vnet.name

  address_prefixes = ["172.16.0.0/20"]
}

# Resources that can be accessed from the DMZ
resource "azurerm_subnet" "public" {
  name                  = "sub-${var.project_name}-public"
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_name  = azurerm_virtual_network.vnet.name

  address_prefixes  = ["172.16.16.0/20"]
  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "delegation"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.Web/serverFarms"
    }
  }
}

# Resources not accessible from the internet
resource "azurerm_subnet" "private" {
  name                  = "sub-${var.project_name}-private"
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_name  = azurerm_virtual_network.vnet.name

  address_prefixes  = ["172.16.128.0/20"]
  service_endpoints = ["Microsoft.Storage", "Microsoft.Web"]

#  delegation {
#    name = "delegation"
#    service_delegation {
#      name = "Microsoft.Web/serverFarms"
#    }
#  }
}

resource "azurerm_public_ip" "gateway_ip" {
  name                = "gatewayip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
