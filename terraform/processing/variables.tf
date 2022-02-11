# Load common module
module "common" {
  source = "../common"
}
variable "data_storage_account" {
  description = "Storage account containing input data"
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
# Local variables
locals {
  tags = merge(
    {
      "module" = "processing"
    },
    module.common.tags,
  )
  version   = yamldecode(file("../azfunctions/config.yaml"))["version"]
  functions = yamldecode(file("../azfunctions/config.yaml"))["functions"]
  app_name  = "app-${module.common.project_name}-processing"
  # https://docs.microsoft.com/en-us/azure/azure-functions/functions-premium-plan#available-instance-skus
  # ElasticPremium  EP1  1 core   3.5  GB RAM
  # ElasticPremium  EP2  2 core   7    GB RAM
  # ElasticPremium  EP3  4 core  14    GB RAM
  app_sku_category = "ElasticPremium"
  app_sku          = "EP1"
}
