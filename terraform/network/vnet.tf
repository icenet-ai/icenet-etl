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

  private_endpoint_network_policies_enabled = false
  private_link_service_network_policies_enabled = false

  # Public repository for uploads (via gateway?)
  # Web applications accessed via the gateway
  service_endpoints     = local.svc_endpoints
}

# Resources not accessible from the internet
resource "azurerm_subnet" "private" {
  name                  = "sub-${var.project_name}-private"
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_name  = azurerm_virtual_network.vnet.name

  address_prefixes  = ["172.16.128.0/20"]

  private_endpoint_network_policies_enabled = false
  private_link_service_network_policies_enabled = false

  # Private storage (internal services)
  # Function apps (internal storage/data processing only)
  # PSQL (used by Azure hosted services in public only)
  service_endpoints     = local.svc_endpoints
}

resource "azurerm_public_ip" "gateway_ip" {
  name                = "gatewayip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  ip_tags             = {}
  zones               = []

  tags                = local.tags
}

resource "azurerm_public_ip" "nat_ip" {
  name                = "natip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"

  ip_tags             = {}
  zones               = []

  tags                = local.tags
}
