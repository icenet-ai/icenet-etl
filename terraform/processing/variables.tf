variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

variable "dns_zone" {
  description = "VNet private DNS zone"
}
variable "data_storage_account" {
  description = "Storage account containing input data"
}
variable "data_storage_resource_group" {
  description = "Input storage account resource group"
}
variable "data_topic" {
  description = "Topic for input delivery from storage account"
}
variable "database_fqdn" {
  description = "Database server FQDN"
  type        = string
}
variable "database_host" {
  description = "Database server hostname"
  type        = string
}
variable "database_name" {
  description = "Database name"
  type        = string
}
variable "database_user" {
  description = "Database username"
  type        = string
}
variable "database_password" {
  description = "Database username"
  type        = string
}
variable "database_resource_group_name" {
  type        = string
  description = "Resource group of the storage account"
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
      "module" = "processing"
    },
    var.default_tags,
  )
  app_name  = "app-${var.project_name}-processing"

  # https://docs.microsoft.com/en-us/azure/azure-functions/functions-premium-plan#available-instance-skus
  # ElasticPremium  EP1  1 core   3.5  GB RAM
  # ElasticPremium  EP2  2 core   7    GB RAM
  # ElasticPremium  EP3  4 core  14    GB RAM
  app_sku_category = "ElasticPremium"
  app_sku          = "EP1"
  event_retries    = 1
  event_ttl        = 1
}
