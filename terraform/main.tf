# Secrets module
module "secrets" {
  source              = "./secrets"
  developers_group_id = var.developers_group_id
  tenant_id           = var.tenant_id
}

# Logging module
module "logging" {
  source         = "./logging"
}

# Database module
module "database" {
  source               = "./database"
  storage_mb           = 5120
  allowed_cidrs        = var.users_ip_addresses
  key_vault_id         = module.secrets.key_vault_id
  logging_workspace_id = module.logging.logging_workspace_id
  database_names       = ["icenet"]
}
