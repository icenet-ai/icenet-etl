output "rg_name" {
  description = "Resource group of the networks base"
  value       = azurerm_resource_group.this.name
}
output "vnet" {
  description = "Azure VNet"
  value       = azurerm_virtual_network.vnet
}
output "gateway_subnet" {
  description = "Gateway subnet"
  value       = azurerm_subnet.gateway
}
output "public_subnet" {
  description = "Public subnet"
  value       = azurerm_subnet.public
}
output "private_subnet" {
  description = "Private subnet"
  value       = azurerm_subnet.private
}
output "dns_zone" {
  description = "Link to the private DNS zone for this network"
  value       = azurerm_private_dns_zone.this
}
output "gateway_ip" {
  description = "Gateway main IP"
  value       = azurerm_public_ip.gateway_ip
}
