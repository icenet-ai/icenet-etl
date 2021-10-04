output "storage_account" {
  description = "Storage account"
  value       = azurerm_storage_account.this
}
output "storage_account_rg_name" {
  description = "Resource group of the storage account"
  value       = azurerm_resource_group.this.name
}
