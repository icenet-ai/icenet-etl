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

# Load common module
module "common" {
  source = "../common"
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "secrets"
    },
    module.common.tags,
  )
}
