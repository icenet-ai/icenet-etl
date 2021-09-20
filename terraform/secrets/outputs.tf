output "key_vault_id" {
  description = "ID of the Azure KeyVault"
  value = "${azurerm_key_vault.this.id}"
}
