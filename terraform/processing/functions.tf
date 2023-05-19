## https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration

# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-processing"
  location = var.location
  tags     = local.tags
}

# For storing logs
resource "azurerm_application_insights" "this" {
  name                = "insights-${var.project_name}-processing"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  tags                = local.tags
}

# Create the storage account
resource "azurerm_storage_account" "this" {
  name                     = "st${var.project_name}processing"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags                     = local.tags
}
resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id         = azurerm_storage_account.this.id

  default_action             = "Allow"
  ip_rules                   = []
  virtual_network_subnet_ids = [var.subnet]
  bypass                     = []
}

# Storage container for deploying functions
resource "azurerm_storage_container" "this" {
  name                  = "deployments"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Service plan that functions belong to
resource "azurerm_service_plan" "this" {
  name                         = "plan-${var.project_name}-processing"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location

  os_type                      = "Linux"
  maximum_elastic_worker_count = 20
  sku_name                     = local.app_sku
  lifecycle {
    ignore_changes = [kind]
  }
  tags = local.tags
}

# Functions to be deployed
resource "azurerm_linux_function_app" "this" {
  name                        = local.app_name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name

  service_plan_id             = azurerm_service_plan.this.id
  storage_account_name        = var.data_storage_account.name
  storage_account_access_key  = var.data_storage_account.primary_access_key

  site_config {
    elastic_instance_minimum  = 1
    use_32_bit_worker         = false
    application_insights_connection_string = "InstrumentationKey=${azurerm_application_insights.this.instrumentation_key}"
    application_insights_key  = "${azurerm_application_insights.this.instrumentation_key}"
    application_stack {
      python_version = "3.9"
    }
    ip_restriction {
      virtual_network_subnet_id = var.subnet
    }
  }
  app_settings = {
    "BUILD_FLAGS"                           = "UseExpressBuild"
    "ENABLE_ORYX_BUILD"                     = "true"
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "PSQL_DB"                               = var.database_name
    "PSQL_HOST"                             = var.database_fqdn
    "PSQL_PWD"                              = var.database_password
    "PSQL_USER"                             = var.database_user
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "1"
    "XDG_CACHE_HOME"                        = "/tmp/.cache"
  }
  tags = local.tags
}

# Actual function deployment
resource "null_resource" "functions" {
  # These define build order
  depends_on = [azurerm_service_plan.this, azurerm_linux_function_app.this]

  # These will trigger a redeploy
  triggers = {
    functions    = "${local.version}_${join("+", [for value in local.functions : value["name"]])}"
    service_plan = "${azurerm_service_plan.this.id}_${local.app_sku}"
    function_app = "${azurerm_linux_function_app.this.id}_${azurerm_linux_function_app.this.site_config[0].application_stack[0].python_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
    echo "Waiting for other deployments to finish..."
    sleep 150
    cd ../azfunctions/processing
    echo "Deploying functions from $(pwd)"
    func azure functionapp publish ${local.app_name} --python
    cd -
    EOF
  }
}
