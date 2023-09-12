
# Service plan that functions belong to
resource "azurerm_service_plan" "this" {
  name                = "plan-${var.project_name}-application"
  resource_group_name = var.webapps_resource_group.name
  location            = var.location

  os_type                      = "Linux"
  worker_count                 = 1

  sku_name                     = local.app_sku
  tags = local.tags
}

# Functions to be deployed
resource "azurerm_linux_web_app" "this" {
  name                       = "web-${var.project_name}-application"
  location                   = var.location
  resource_group_name        = var.webapps_resource_group.name
  service_plan_id            = azurerm_service_plan.this.id

  site_config {
    use_32_bit_worker = false
    always_on         = true
    application_stack {
      python_version = "3.8"
    }
    app_command_line = "gunicorn icenet_app.app:app"
  }

  app_settings = {
    "ICENET_DATA_LOCATION"    = "/data"
#    "ENABLE_ORYX_BUILD"              = "true"
#    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  storage_account {
    account_name  = var.data_storage_account.name
    access_key    = var.data_storage_account.primary_access_key
    name          = "data"
    share_name    = "data"
    type          = "AzureFiles"
    mount_path    = "/data"
  }

  tags = local.tags
}

#resource "azurerm_private_endpoint" "application" {
#  name                = "pvt-${var.project_name}-application"
#  location            = var.webapps_resource_group.location
#  resource_group_name = var.webapps_resource_group.name
#  subnet_id           = var.subnet_id
#
#  private_service_connection {
#    name              = "pvt-${var.project_name}-application"
#    is_manual_connection = "false"
#    private_connection_resource_id = azurerm_linux_web_app.this.id
#    subresource_names = ["sites"]
#  }
#
#  private_dns_zone_group {
#    name                 = "default"
#    private_dns_zone_ids = [var.dns_zone.id]
#  }
#}
