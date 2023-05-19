output "connection_string" {
  description = "Connection string for communications services"
  value = "${azurerm_communication_service.comms.primary_connection_string}"
}

output "connection_key" {
  description = "Connection key for communications services"
  value = "${azurerm_communication_service.comms.primary_key}"
  sensitive = true
}
