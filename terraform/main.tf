# Terraform secrets module
module "secrets" {
  source    = "./secrets"
  tenant_id = var.tenant_id
}