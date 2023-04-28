resource "azurerm_network_security_group" "public" {
  name                = "nsg-${var.project_name}-public"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "private" {
  name                = "nsg-${var.project_name}-private"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

# Firewall rules
resource "azurerm_network_security_rule" "net_rules" {
  for_each                    = { for name, cidr_block in var.users_ip_addresses : name => cidr_block }
  name                        = "AllowConnectionsFrom${each.key}"
  priority                    = index(values(var.users_ip_addresses), each.value) + 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = each.value
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.public.name
}
