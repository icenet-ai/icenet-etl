output "rg_name" {
  description = "Resource group of the networks base"
  value       = azurerm_resource_group.this.name
}
output "gateway_subnet_id" {
  description = "Gateway subnet ID"
  value       = azurerm_subnet.gateway.id
}
output "public_subnet_id" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}
output "private_subnet_id" {
  description = "Private subnet ID"
  value       = azurerm_subnet.private.id
}
