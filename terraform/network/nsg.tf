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
