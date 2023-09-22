# Create the storage account
resource "azurerm_storage_account" "data" {
  name                     = "st${var.project_name}data"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"

  public_network_access_enabled = true

  network_rules {
    default_action             = "Allow"
#    virtual_network_subnet_ids = [
#      var.public_subnet_id,
#      var.private_subnet_id
#    ]
#    ip_rules = [
#      for ip in var.allowed_cidrs : replace(ip, "/32", "")
#    ]
    bypass                     = ["AzureServices"]
  }

  tags                     = local.tags
}

# TODO: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-networking-endpoints?tabs=azure-portal
#resource "azurerm_private_endpoint" "data_blob" {
#  name                = "pvt-${var.project_name}-data-blob"
#  location            = azurerm_resource_group.this.location
#  resource_group_name = azurerm_resource_group.this.name
#  subnet_id           = var.public_subnet_id
#
#  private_service_connection {
#    name              = "pvt-${var.project_name}-data-blob"
#    is_manual_connection = "false"
#    private_connection_resource_id = azurerm_storage_account.data.id
#    subresource_names = ["blob"]
#  }
#
#  private_dns_zone_group {
#    name                 = "default"
#    private_dns_zone_ids = [var.dns_zone.id]
#  }
#}
#
#resource "azurerm_private_endpoint" "data_file" {
#  name                = "pvt-${var.project_name}-data-file"
#  location            = azurerm_resource_group.this.location
#  resource_group_name = azurerm_resource_group.this.name
#  subnet_id           = var.public_subnet_id
#
#  private_service_connection {
#    name              = "pvt-${var.project_name}-data-file"
#    is_manual_connection = "false"
#    private_connection_resource_id = azurerm_storage_account.data.id
#    subresource_names = ["file"]
#  }
#
#  private_dns_zone_group {
#    name                 = "default"
#    private_dns_zone_ids = [var.dns_zone.id]
#  }
#}

# Create the storage container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.data.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "data_share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.data.name
  quota                = 500

  acl {
    id = "4c35c723-1b33-44f9-af48-4d91c72b6d7e"

    access_policy {
      permissions = "rwdl"
      start       = "2023-07-31T00:00:00.0000000Z"
      expiry      = "2023-12-31T00:00:00.0000000Z"
    }
  }
}

## Storage events
resource "azurerm_eventgrid_system_topic" "data" {
  name                = "egs-${var.project_name}-data-topic"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  source_arm_resource_id = azurerm_storage_account.data.id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  tags = local.tags
}
