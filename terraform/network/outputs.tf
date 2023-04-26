output "rg_name" {
  description = "Resource group of the networks base"
  value       = azurerm_resource_group.this.name
}
output "public_subnet" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}
output "private_subnet" {
  description = "Private subnet ID"
  value       = azurerm_subnet.private.id
}
