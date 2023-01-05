variable "resource_group_name" {
  type        = string
  description = "Resource group of ETL resources"
}
variable "storage_resource_group_name" {
  type        = string
  description = "Storage resource group name"
}
variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

variable "storage_id" {
    description = "Storage resource ID for data arrival topic"
    type    = string
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
      "module" = "outputs"
    },
    var.default_tags,
  )
}

