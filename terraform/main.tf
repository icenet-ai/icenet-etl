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

# NetCDF processing
module "processing" {
  source                       = "./processing"
  data_storage_account         = module.data.storage_account
  database_resource_group_name = module.data.resource_group
  database_fqdn                = module.data.server_fqdn
  database_host                = module.data.server_name
  database_name                = module.data.database_names[0]
  database_user                = module.data.admin_username
  database_password            = module.data.admin_password
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
  subnet                       = module.network.private_subnet_id
}

##
# Linkages, quite likely should always be at the end of the run
#

# Event grid topics for integrations
module "events" {
  source                       = "./events"

  processing_resource_group_name = module.processing.resource_group
  storage_resource_group_name  = module.data.resource_group
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
  input_storage_account_id     = module.data.storage_account.id
}
