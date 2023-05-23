# These variables must be passed at terraform time (CLI, tfvars, etc...)
variable "users_ip_addresses" {
  type        = map(string)
  description = "List of CIDRs that users can connect from"
}
variable "developers_group_id" {
  description = "Azure group containing all developers"
  type        = string
}
variable "subscription_id" {
  description = "Which Azure subscription to build in"
  type        = string
}
variable "tenant_id" {
  description = "Which Azure tenant to build in"
  type        = string
}

# These have sensible defaults
variable "environment" {
  description = "Environment we're building"
  default     = "dev"
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}
variable "project_prefix" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "icenetetl"
}

variable "deploy_dashboard" {
  description = "Deploy the icenet-dashboard application"
  type        = bool
  default     = true
}

variable "deploy_registry" {
  description = "Deploy the icenet-registry application"
  type        = bool
  default     = true
}

# Local variables
locals {
  project_name   = "${var.project_prefix}${var.environment}"
  tags = {
    "deployed_by" : "Terraform"
    "project" :     "IceNet"
    "component" :   "ETL"
  }
}
