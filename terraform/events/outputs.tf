output "processing_endpoint" {
  description = "Endpoint of the processing event topic"
  value       = azurerm_eventgrid_topic.processing.endpoint
}
output "processing_shared_key" {
  description = "Access key of the processing event topic"
  value       = azurerm_eventgrid_topic.processing.primary_access_key
  sensitive   = true
}

