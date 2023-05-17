# Network module
module "network" {
  source              = "./network"
  location            = var.location
  project_name        = local.project_name
  default_tags        = local.tags
  users_ip_addresses  = var.users_ip_addresses
}

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
  private_subnet      = module.network.private_subnet_id
  public_subnet       = module.network.public_subnet_id
  storage_mb          = 8192
  key_vault_id        = module.secrets.key_vault_id  
}


















# Database module
#module "database" {

#}

# NetCDF processing
#module "processing" {
#  source                       = "./processing"
#  data_storage_account         = module.data.storage_account
#  database_resource_group_name = module.data.rg_name
#  database_fqdn                = module.database.server_fqdn
#  database_host                = module.database.server_name
#  database_name                = local.database_names[0]
#  database_user                = module.database.admin_username
#  database_password            = module.database.admin_password
#  location                     = var.location
#  project_name                 = local.project_name
#  default_tags                 = local.tags
#  subnet                       = module.network.private_subnet
#}


# Event grid topics for integrations
#module "events" {
#  source                       = "./events"

#  resource_group_name          = module.processing.rg_name
#  storage_resource_group_name  = module.storage.rg_name
#  location                     = var.location
#  project_name                 = local.project_name
#  default_tags                 = local.tags
#  storage_id                   = module.storage.storage_account.id
#}
