variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

variable "processing_storage_account" {
  description = "Storage account for processing data"
}
variable "input_storage_account" {
  description = "Storage account containing inputs"
}
variable "input_storage_resource_group" {
  description = "Input storage account resource group"
}

variable "subnet" {
    description = "Subnet to deploy in"
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
}