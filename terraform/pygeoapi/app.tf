
# Service plan that functions belong to
resource "azurerm_service_plan" "this" {
  name                = "plan-${var.project_name}-pygeoapi"
  resource_group_name = var.webapps_resource_group.name
  location            = var.location

  os_type                      = "Linux"
  worker_count                 = 1

  sku_name                     = local.app_sku
  lifecycle {
    ignore_changes = [kind]
  }
  tags = local.tags
}

# Functions to be deployed
resource "azurerm_linux_web_app" "this" {
  name                       = "app-${var.project_name}-pygeoapi"
  location                   = var.location
  resource_group_name        = var.webapps_resource_group.name
  service_plan_id            = azurerm_service_plan.this.id

  site_config {
    use_32_bit_worker         = false
    always_on        = true
    application_stack {
      python_version = "3.9"
    }
    app_command_line = "python run.py"
    ip_restriction {
      virtual_network_subnet_id = var.subnet
    }
  }
  app_settings = {
    "POST_BUILD_COMMAND"             = "post_build.sh",
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "1",
    "WEBSITES_PORT"                  = "${var.pygeoapi_input_port}",
  }
  tags = local.tags
}
