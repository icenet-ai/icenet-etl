# Secrets module
module "secrets" {
  source    = "./secrets"
  developers_group_id = var.developers_group_id
  tenant_id = var.tenant_id
}