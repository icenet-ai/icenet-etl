# Load common module
module "common" {
  source = "../common"
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "storage"
    },
    module.common.tags,
  )
}
