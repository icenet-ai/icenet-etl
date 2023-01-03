resource "azurerm_eventgrid_topic" "processing" {
  name                = "etl-${var.project_name}-processing-topic"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.tags
}
