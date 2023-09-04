variable "project_name" {
  description = "Project name for resource naming"
  type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

variable "processing_resource_group" {
  description = "Resource group for processing"
}
variable "data_storage_account" {
  description = "Storage account containing inputs"
}
variable "data_storage_resource_group" {
  description = "Input storage account resource group"
}
variable "data_topic" {
  description = "Topic for input delivery from storage account"
}
variable "docker_username" {
  description = "Which Docker username to user"
  type        = string
  sensitive   = true
}
variable "docker_password" {
  description = "Which Docker password to password"
  type        = string
  sensitive   = true
}
variable "notification_email" {
  description = "Email to send notifications to"
  type        = string
}
variable "sendfrom_email" {
  description = "Email to use for sending notifications from"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
    description = "Subnet ID to deploy in"
    type = string
}

variable "default_tags" {
    description = "Default tags for resources"
    type    = map(string)
    default = {}
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "forecast_processor"
    },
    var.default_tags,
  )
  app_name  = "app-${var.project_name}-event-processing"
  # https://docs.microsoft.com/en-us/azure/azure-functions/functions-premium-plan#available-instance-skus
  # ElasticPremium  EP1  1 core   3.5  GB RAM
  # ElasticPremium  EP2  2 core   7    GB RAM
  # ElasticPremium  EP3  4 core  14    GB RAM
  # app_sku_category = "ElasticPremium"
  app_sku          = "EP1"
  event_retries    = 1
  event_ttl        = 1
}
