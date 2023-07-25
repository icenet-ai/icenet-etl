# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-fcproc"
  location = var.location
  tags     = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "insights-${var.project_name}-fcproc"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_communication_service" "comms" {
  name                = "${var.project_name}-comms"
  resource_group_name = azurerm_resource_group.this.name
  # This cannot be UK due to email being global - US only
  # data_location       = "UK"
  data_location       = "United States"
  tags                = local.tags
}

resource "azurerm_email_communication_service" "emails" {
  name                = "${var.project_name}-emails"
  resource_group_name = azurerm_resource_group.this.name
  # This cannot be UK due to email being global - US only
  # data_location       = "UK"
  data_location       = "United States"
  tags                = local.tags
}

# Service plan that functions belong to
resource "azurerm_service_plan" "this" {
  name                         = "plan-${var.project_name}-evtproc"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  os_type                      = "Linux"
  maximum_elastic_worker_count = 2
  sku_name                     = local.app_sku
  tags                         = local.tags
}

# Functions to be deployed
resource "azurerm_linux_function_app" "this" {
  name                       = local.app_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = var.processing_storage_account.name
  storage_account_access_key = var.processing_storage_account.primary_access_key
  site_config {
    elastic_instance_minimum  = 1
    use_32_bit_worker         = false
    application_insights_connection_string = "InstrumentationKey=${azurerm_application_insights.this.instrumentation_key}"
    application_insights_key  = "${azurerm_application_insights.this.instrumentation_key}"
    application_stack {
      docker {
        registry_url            = "registry.hub.docker.com"
        registry_username       = var.docker_username
        registry_password       = var.docker_password
        image_name              = "jimcircadian/iceneteventprocessor"
        image_tag               = "latest"
      }
    }
    vnet_route_all_enabled = true
  }
  # virtual_network_subnet_id = var.subnet_id
  app_settings = {
    "COMMS_ENDPOINT"                 = azurerm_communication_service.comms.primary_connection_string
    "COMMS_TO_EMAIL"                 = var.notification_email
    "COMMS_FROM_EMAIL"               = var.sendfrom_email
    # Must have this for using docker containers, or persistent storage will be
    # enabled which mounts over the contents of the container.
    # https://github.com/Azure/azure-functions-docker/issues/642
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
  tags = local.tags
}
