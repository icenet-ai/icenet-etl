variable "storage_account" {
  description = "Storage account"
}

# Load common module
module "common" {
  source = "../common"
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "processing"
    },
    module.common.tags,
  )
  version   = yamldecode(file("../azfunctions/config.yaml"))["version"]
  functions = yamldecode(file("../azfunctions/config.yaml"))["functions"]
  app_name  = "app-${module.common.project_name}-processing"
}
