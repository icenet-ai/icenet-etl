variable "developers_group_id" {
  description = "Azure group containing all developers"
  type        = string
}
variable "tenant_id" {
  description = "Which Azure tenant to build in"
  type        = string
}
variable "key_permissions" {
  description = "Default permissions for keys"
  type        = list(string)
  default     = ["create", "delete", "get", "list"]
}
variable "secret_permissions" {
  description = "Default permissions for secrets"
  type        = list(string)
  default     = ["set", "delete", "get", "list"]
}
variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
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
      "module" = "secrets"
    },
    var.default_tags,
  )
}
