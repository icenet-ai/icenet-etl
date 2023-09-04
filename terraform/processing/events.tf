resource "azurerm_eventgrid_system_topic_event_subscription" "egs-processing-data-topic" {
  name                = "sub-proc-${var.project_name}-data-topic"
  system_topic        = var.data_topic.name

  # This is documented as the location of the system topic, but it still throws resource not found
  resource_group_name = var.data_storage_resource_group.name
  depends_on          = [azurerm_linux_function_app.this]

  # https://learn.microsoft.com/en-us/azure/event-grid/event-schema-blob-storage?tabs=event-grid-event-schema
  included_event_types = [
    "Microsoft.Storage.BlobCreated",
  ]

  azure_function_endpoint {
    function_id       =   "${azurerm_linux_function_app.this.id}/functions/InputBlobTrigger"
    max_events_per_batch = 1
    preferred_batch_size_in_kilobytes = 64
  }

  retry_policy {
    max_delivery_attempts   = local.event_retries
    event_time_to_live      = local.event_ttl
  }

  subject_filter {
    subject_ends_with       = ".nc"
  }

  advanced_filter {
    string_in {
      key    = "data.api"
      values = ["PutBlob", "PutBlockList"]
    }
  }
}
