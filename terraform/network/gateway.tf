# TODO: instead of admin access to all subnets, use bastions and facilitate
# deployment via azure devops to the web applications
#resource "azurerm_bastion_host" "this" {
#  name                = "bastion"
#  location            = azurerm_resource_group.this.location
#  resource_group_name = azurerm_resource_group.this.name
#
#  ip_configuration {
#    name                 = "configuration"
#    subnet_id            = azurerm_subnet.gateway.id
#    public_ip_address_id = azurerm_public_ip.gateway_ip.id
#  }
#}
