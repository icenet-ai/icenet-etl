# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-processing"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "processor" {
  name                     = "st${var.project_name}appproc"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# For storing logs
resource "azurerm_application_insights" "this" {
  name                = "insights-${var.project_name}-processing"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  tags                = local.tags
}

# Service plan that functions belong to
resource "azurerm_service_plan" "this" {
  name                         = "plan-${var.project_name}-processing"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location

  os_type                      = "Linux"
  maximum_elastic_worker_count = 20
  sku_name                     = local.app_sku
  tags = local.tags
}

# Functions to be deployed
resource "azurerm_linux_function_app" "this" {
  name                        = local.app_name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name

  service_plan_id             = azurerm_service_plan.this.id
  storage_account_name        = azurerm_storage_account.processor.name
  storage_account_access_key  = azurerm_storage_account.processor.primary_access_key

  site_config {
    elastic_instance_minimum  = 1
    use_32_bit_worker         = false
    application_insights_connection_string = "InstrumentationKey=${azurerm_application_insights.this.instrumentation_key}"
    application_insights_key  = "${azurerm_application_insights.this.instrumentation_key}"
    application_stack {
      python_version = "3.9"
    }
    ip_restriction {
      virtual_network_subnet_id = var.subnet_id
    }
  }
  app_settings = {
    "BUILD_FLAGS"                           = "UseExpressBuild"
    "ENABLE_ORYX_BUILD"                     = "true"
    # TODO: update after forecast-processor implementation, rather than manual
    #"EVENTGRID_DOMAIN_KEY"
    "EVENTGRID_DOMAIN_TOPIC"                = "eg-${var.project_name}-processing-topic"
    "EVENTGRID_DOMAIN_ENDPOINT"             = "https://egd-${var.project_name}-processing-domain.${var.location}-1.eventgrid.azure.net/api/events"
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "PSQL_DB"                               = var.database_name
    "PSQL_HOST"                             = var.database_fqdn
    "PSQL_PWD"                              = var.database_password
    "PSQL_USER"                             = var.database_user
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "1"
    "XDG_CACHE_HOME"                        = "/tmp/.cache"
  }
  storage_account {
    account_name        = var.data_storage_account.name
    access_key          = var.data_storage_account.primary_access_key
    name                = "InputData"
    share_name          = "data"
    type                = "AzureBlob"
    mount_path          = "/data"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}
