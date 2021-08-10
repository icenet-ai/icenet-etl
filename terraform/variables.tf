# These variables must be passed at the command line
variable "subscription_id" {
  description = "Which Azure subscription to build in"
  type        = string
}

variable "tenant_id" {
  description = "Which Azure tenant to build in"
  type        = string
}