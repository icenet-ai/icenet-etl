resource "azurerm_eventgrid_topic" "processing" {
  name                = "etl-${var.project_name}-processing-topic"
  location            = var.location
  resource_group_name = var.processing_resource_group_name

  tags = local.tags
}

resource "azurerm_eventgrid_system_topic" "storage" {
  name                = "etl-${var.project_name}-forecast-topic"
  location            = var.location
  resource_group_name = var.storage_resource_group_name

  source_arm_resource_id = var.input_storage_account_id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  tags = local.tags
}
