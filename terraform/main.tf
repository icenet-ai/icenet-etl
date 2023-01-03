# Secrets module
module "secrets" {
  source              = "./secrets"
  developers_group_id = var.developers_group_id
  location            = var.location
  project_name        = local.project_name
  default_tags        = local.tags
  tenant_id           = var.tenant_id
}

# Data storage
module "data" {
  source = "./data"
  default_tags        = local.tags
  location            = var.location
  project_name        = local.project_name
}

# Logging module
module "logging" {
  source = "./logging"
  default_tags        = local.tags
  location            = var.location
  project_name        = local.project_name
}

# Database module
module "database" {
  source               = "./database"
  resource_group_name  = module.data.rg_name
  location             = var.location
  project_name         = local.project_name
  storage_mb           = 8192
  allowed_cidrs        = var.users_ip_addresses
  key_vault_id         = module.secrets.key_vault_id
  logging_workspace_id = module.logging.logging_workspace_id
  database_names       = local.database_names
  default_tags         = local.tags
}

# NetCDF processing
module "processing" {
  source                       = "./processing"
  data_storage_account         = module.data.storage_account
  database_resource_group_name = module.data.rg_name
  database_fqdn                = module.database.server_fqdn
  database_host                = module.database.server_name
  database_name                = local.database_names[0]
  database_user                = module.database.admin_username
  database_password            = module.database.admin_password
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
}

# Event grid topics for integrations
module "events" { 
  source                       = "./events"
  
  resource_group_name          = module.processing.rg_name
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
}
