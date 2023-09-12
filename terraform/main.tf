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
  allowed_cidrs       = var.users_ip_addresses
  default_tags        = local.tags
  location            = var.location
  project_name        = local.project_name
  private_subnet_id   = module.network.private_subnet.id
  public_subnet_id    = module.network.public_subnet.id
  storage_mb          = 8192
  key_vault_id        = module.secrets.key_vault_id
  dns_zone            = module.network.dns_zone
}

# PyGeoAPI app
module "pygeoapi" {
  source                      = "./pygeoapi"
  postgres_db_name            = module.data.database_names[0]
  postgres_db_host            = module.data.server_fqdn
  postgres_db_reader_username = module.data.reader_username
  postgres_db_reader_password = module.data.reader_password
  pygeoapi_input_port         = "8000"
  default_tags                = local.tags
  project_name                = local.project_name
  location                    = var.location
  subnet_id                   = module.network.public_subnet.id
  dns_zone                    = module.network.dns_zone
  webapps_resource_group      = module.web.resource_group
  config_output_location      = var.pygeoapi_config_output_location
}

# Dashboard and data access application
module "application" {
  source                      = "./application"
  default_tags                = local.tags
  project_name                = local.project_name
  location                    = var.location
  subnet_id                   = module.network.public_subnet.id
  dns_zone                    = module.network.dns_zone
  data_storage_account        = module.data.storage_account
  webapps_resource_group      = module.web.resource_group
}

##
# Downstream processing elements, quite likely should always be at the end of the run
#
# These exist in the private subnet, as access is delegated to web applications
# and these are typically function apps running without exposed interfaces

# NetCDF processing
module "processing" {
  source                       = "./processing"
  data_storage_account         = module.data.storage_account
  data_storage_resource_group  = module.data.resource_group
  database_resource_group_name = module.data.resource_group.name
  database_fqdn                = module.data.server_fqdn
  database_host                = module.data.server_name
  database_name                = module.data.database_names[0]
  database_user                = module.data.admin_username
  database_password            = module.data.admin_password
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
  subnet_id                    = module.network.private_subnet.id
  data_topic                   = module.data.data_system_topic
  dns_zone                     = module.network.dns_zone
}

# Forecast event processing and event grid subs
module "forecast_processor" {
  source                       = "./forecast_processor"
  location                     = var.location
  project_name                 = local.project_name
  default_tags                 = local.tags
  data_storage_account         = module.data.storage_account
  data_storage_resource_group  = module.data.resource_group
  data_topic                   = module.data.data_system_topic
  processing_resource_group    = module.processing.resource_group
  subnet_id                    = module.network.private_subnet.id
  docker_username              = var.docker_username
  docker_password              = var.docker_password
  notification_email           = var.notification_email
  sendfrom_email               = var.sendfrom_email
  dns_zone                     = module.network.dns_zone
}

module "web" {
  source                      = "./web"
  default_tags                = local.tags
  project_name                = local.project_name
  location                    = var.location
  frontend_ip                 = module.network.gateway_ip
  subnet_id                   = module.network.gateway_subnet.id
  domain_name                 = var.domain_name
  environment                 = var.environment
  # TODO: endpoints from application, data, pygeoapi
}
