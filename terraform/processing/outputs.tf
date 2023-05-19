output "resource_group" {
  description = "Resource group of the processing resources"
  value       = azurerm_resource_group.this.name
}
