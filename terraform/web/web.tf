# Create the resource group
resource "azurerm_resource_group" "webapps" {
  name     = "rg-${var.project_name}-webapps"
  location = var.location
  tags     = local.tags
}

# Use one of for layer 7:
#   Azure Application Gateway

locals {
  frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4"
  frontend_port_name = "port_80"
}

resource "azurerm_application_gateway" "entrypoint" {
  name                = "ag-${var.project_name}-webapps"
  resource_group_name = azurerm_resource_group.webapps.name
  location            = var.location

  enable_http2                      = false
  fips_enabled                      = false
  force_firewall_policy_association = false
  zones                             = []

  backend_address_pool {
    name         = "ag-pool-${var.project_name}-geoapi"
    fqdns        = [
      "app-${var.project_name}-pygeoapi.azurewebsites.net",
    ]
    ip_addresses = []
  }
  backend_address_pool {
    name         = "ag-pool-${var.project_name}-web"
    fqdns        = [
      "web-${var.project_name}-application.azurewebsites.net",
    ]
    ip_addresses = []
  }
#  backend_address_pool {
#    name         = "ag-pool-${var.project_name}-data"
#    fqdns        = [
#      "st${var.project_name}data.blob.core.windows.net",
#    ]
#    ip_addresses = []
#  }

  backend_http_settings {
      cookie_based_affinity               = "Disabled"
      name                                = "default-http-settings"
      pick_host_name_from_backend_address = false
      port                                = 80
      protocol                            = "Http"
      request_timeout                     = 20
      trusted_root_certificate_names      = []
  }
  backend_http_settings {
      cookie_based_affinity               = "Disabled"
      name                                = "geoapi-settings"
      host_name                           = "app-${var.project_name}-pygeoapi.azurewebsites.net"
      pick_host_name_from_backend_address = false
      port                                = 80
      protocol                            = "Http"
      request_timeout                     = 20
      trusted_root_certificate_names      = []
  }
  backend_http_settings {
      cookie_based_affinity               = "Disabled"
      name                                = "web-settings"
      host_name                           = "web-${var.project_name}-application.azurewebsites.net"
      pick_host_name_from_backend_address = false
      port                                = 80
      probe_name                          = "auth_probe"
      protocol                            = "Http"
      request_timeout                     = 20
      trusted_root_certificate_names      = []
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.frontend_ip.id
    private_ip_address_allocation = "Dynamic"
  }

  gateway_ip_configuration {
    name      = "ag-ip-${var.project_name}-configuration"
    subnet_id = var.subnet_id
  }

  http_listener {
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      host_name                      = "api.${var.environment}.${var.domain_name}"
      name                           = "ag-rule-${var.project_name}-geoapi"
      protocol                       = "Http"
      require_sni                    = false
  }
  http_listener {
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      host_name                      = "app.${var.environment}.${var.domain_name}"
      name                           = "ag-rule-${var.project_name}-app"
      protocol                       = "Http"
      require_sni                    = false
  }
  http_listener {
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      host_name                      = "assets.${var.environment}.${var.domain_name}"
      name                           = "ag-rule-${var.project_name}-assets"
      protocol                       = "Http"
      require_sni                    = false
  }
  http_listener {
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      host_name                      = "dashboard.${var.environment}.${var.domain_name}"
      name                           = "ag-rule-${var.project_name}-dashboard"
      protocol                       = "Http"
      require_sni                    = false
  }
#  http_listener {
#      frontend_ip_configuration_name = local.frontend_ip_configuration_name
#      frontend_port_name             = local.frontend_port_name
#      host_name                      = "data.${var.environment}.${var.domain_name}"
#      name                           = "ag-rule-${var.project_name}-data"
#      protocol                       = "Http"
#      require_sni                    = false
#  }

  probe {
    interval            = 30
    minimum_servers     = 0
    name                = "auth_probe"
    path                = "/"
    pick_host_name_from_backend_http_settings = true
    protocol            = "Http"
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = [
        "200-399",
        "401",
      ]
    }
  }

  request_routing_rule {
      backend_address_pool_name  = "ag-pool-${var.project_name}-geoapi"
      backend_http_settings_name = "geoapi-settings"
      http_listener_name         = "ag-rule-${var.project_name}-geoapi"
      name                       = "ag-rule-${var.project_name}-geoapi"
      priority                   = 1000
      rule_type                  = "Basic"
  }
  request_routing_rule {
      backend_address_pool_name  = "ag-pool-${var.project_name}-web"
      backend_http_settings_name = "web-settings"
      http_listener_name         = "ag-rule-${var.project_name}-app"
      name                       = "ag-rule-${var.project_name}-app"
      priority                   = 1001
      rule_type                  = "Basic"
  }
  request_routing_rule {
      backend_address_pool_name  = "ag-pool-${var.project_name}-web"
      backend_http_settings_name = "web-settings"
      http_listener_name         = "ag-rule-${var.project_name}-dashboard"
      name                       = "ag-rule-${var.project_name}-dashboard"
      priority                   = 1002
      rule_type                  = "Basic"
  }
  request_routing_rule {
      backend_address_pool_name  = "ag-pool-${var.project_name}-web"
      backend_http_settings_name = "web-settings"
      http_listener_name         = "ag-rule-${var.project_name}-assets"
      name                       = "ag-rule-${var.project_name}-assets"
      priority                   = 1003
      rule_type                  = "Basic"
  }
#  request_routing_rule {
#      backend_address_pool_name  = "ag-pool-${var.project_name}-data"
#      backend_http_settings_name = "default-http-settings"
#      http_listener_name         = "ag-rule-${var.project_name}-data"
#      name                       = "ag-rule-${var.project_name}-data"
#      priority                   = 1004
#      rule_type                  = "Basic"
#  }

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  tags     = local.tags
}
