variable "project_name" {
    description = "Project name for resource naming"
    type    = string
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}

variable "backend_svc_endpoints" {
  description = "Selection of service endpoints we're using behind the perimeter"
  type = list(string)
  default = []
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
  svc_endpoints = concat(
    var.backend_svc_endpoints,
    ["Microsoft.EventHub", "Microsoft.Storage", "Microsoft.Web", "Microsoft.Sql"]
  )
  tags = merge(
    {
      "module" = "inputs"
    },
    var.default_tags,
  )
}
