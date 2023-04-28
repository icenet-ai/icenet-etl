output "rg_name" {
  description = "Resource group of the networks base"
  value       = azurerm_resource_group.this.name
}
output "public_subnet_id" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}
output "private_subnet_id" {
  description = "Private subnet ID"
  value       = azurerm_subnet.private.id
}
