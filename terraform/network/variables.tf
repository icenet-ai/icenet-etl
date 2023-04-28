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
variable "users_ip_addresses" {
  type        = map(string)
  description = "List of CIDRs that users can connect from"
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "inputs"
    },
    var.default_tags,
  )
}
