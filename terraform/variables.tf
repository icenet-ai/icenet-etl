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
variable "domain_name" {
  description = "Domain name we're using for deployment"
  default     = "icenet.ai"
}
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
  default     = "icenet"
}
variable "docker_username" {
  description = "Which Docker username to user"
  type        = string
  sensitive   = true
}
variable "docker_password" {
  description = "Which Docker password to password"
  type        = string
  sensitive   = true
}
variable "notification_email" {
  description = "Email to send notifications to"
  type        = string
  default     = "test@example.com"
}
variable "sendfrom_email" {
  description = "Email to use for sending notifications from"
  type        = string
  sensitive   = true
  default     = "test@example.com"
}
variable "pygeoapi_config_output_location" {
  description = "Location to output pygeoapi configuration variables to"
  default     = ""
  type        = string
}

# Local variables
locals {
  project_name   = "${var.project_prefix}${var.environment}"
  tags = {
    "deployed_by" : "Terraform"
    "project" :     "IceNet"
    "component" :   "${var.project_prefix}${var.environment}"
  }
}
