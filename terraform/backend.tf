terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.71.0"
    }
  }
  backend "azurerm" {
    container_name       = "blob-icenetetl-terraform"
    key                  = "terraform.tfstate"
    storage_account_name = "sticenetetlterraform"
  }
}
