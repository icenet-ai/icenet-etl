# These variables must be passed at the command line
variable "users_ip_addresses" {
  type        = list(string)
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
# Local variables
locals {
  database_names = ["icenet"]
}
