
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
      virtual_network_subnet_id = var.subnet_id
    }
  }
  app_settings = {
    "POST_BUILD_COMMAND"             = "post_build.sh",
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "1",
    "WEBSITES_PORT"                  = "${var.pygeoapi_input_port}",
  }
  tags = local.tags
}

#resource "azurerm_app_service_virtual_network_swift_connection" "this" {
#  app_service_id  = azurerm_linux_web_app.this.id
#  subnet_id       = var.subnet_id
#}

resource "azurerm_private_endpoint" "this" {
  name                = "pygeoapiprivateendpoint"
  location            = var.webapps_resource_group.location
  resource_group_name = var.webapps_resource_group.name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = [var.dns_zone.id]
  }

  private_service_connection {
    name = "privateendpointconnection"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    subresource_names = ["sites"]
    is_manual_connection = false
  }
}
