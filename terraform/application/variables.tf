variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}
variable "data_storage_account" {
  description = "Storage account containing inputs"
}
variable "webapps_resource_group" {
  description = "Resource group for webapps"
}

variable "dns_zone" {
  description = "VNet private DNS zone"
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
      "module" = "application"
    },
    var.default_tags,
  )
  # https://azure.microsoft.com/en-us/pricing/details/app-service/windows/
  # Basic B1: 1 core, 1.75 GB memory £51.48/month
  # Standard S1: 1 core, 1.75 GB memory £68.46/month
  # Standard S2: 2 core, 3.5 GB memory £136.91/month
  # Premium P1V2: 1 core, 3.5 GB memory £136.91/month
  # Premium P1V3: 1 core, 8 GB memory £182.36/month
  app_sku          = "B1"
}
