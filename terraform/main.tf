# Secrets module
module "secrets" {
  source    = "./secrets"
  developers_group_id = var.developers_group_id
  tenant_id = var.tenant_id
}

# Database module
module "database" {
  source      = "./database"
  storage_mb  = 5120
  key_vault_id = module.secrets.key_vault_id
  database_names = ["icenet"]
}
