variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

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
  default     = ["Create", "Delete", "Update", "Purge",
                 "Get", "List", "Recover", "Restore"]
}
variable "secret_permissions" {
  description = "Default permissions for secrets"
  type        = list(string)
  default     = ["Set", "Delete", "Get", "List",
                 "Purge", "Recover", "Restore"]
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
