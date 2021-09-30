# Load common module
module "common" {
  source = "../common"
}

# Local variables
locals {
  tags = merge(
    {
      "module" = "inputs"
    },
    module.common.tags,
  )
}
