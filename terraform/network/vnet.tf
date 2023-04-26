resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-network"
  location = var.location
  tags     = local.tags
}

resource "azurerm_network_security_group" "public" {
  name                = "public-security-group"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "private" {
  name                = "private-security-group"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# Firewall rules
#resource "azurerm_network_security_rule" "net_rules" {
#  for_each            = { for name, cidr_block in var.allowed_cidrs : name => cidr_block }
#  name                = "AllowConnectionsFrom${each.key}"
#  priority                    = 100
#  direction                   = "Outbound"
#  access                      = "Allow"
#  protocol                    = "TCP"
#  source_port_range           = "*"
#  destination_port_range      = "*"
#  source_address_prefix       = cidrhost(each.value, 0)
#  destination_address_prefix  = cidrhost(each.value, -1)
#  resource_group_name = var.resource_group_name
#  network_security_group_name = azurerm_network_security_group.example.name
#}

resource "azurerm_virtual_network" "this" {
  name                = "rg-${var.project_name}-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # Class B
  # 172.16.0.0/14 - 172.16.0.1 - 172.19.255.254
  #   172.16.1.0/16 - public
  #   172.16.2.0/16 - private
  address_space       = ["172.16.0.0/14"]

  tags     = local.tags
}

resource "azurerm_subnet" "public" {
  name           = "rg-${var.project_name}-public-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.16.1.0/16"]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet" "private" {
  name                 = "rg-${var.project_name}-private-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.16.2.0/16"]
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}
