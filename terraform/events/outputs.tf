output "processing_endpoint" {
  description = "Endpoint of the processing event topic"
  value       = azurerm_eventgrid_topic.processing.endpoint
}
output "processing_shared_key" {
  description = "Access key of the processing event topic"
  value       = azurerm_eventgrid_topic.processing.primary_access_key
  sensitive   = true
}
output "storage_id" {
  description = "ID of the storage event topic"
  value       = azurerm_eventgrid_system_topic.storage.id
}
output "storage_arm_id" {
  description = "ARM ID of the storage event topic"
  value       = azurerm_eventgrid_system_topic.storage.metric_arm_resource_id
}

