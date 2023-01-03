terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.71.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.7.0"
    }
  }
  backend "azurerm" {
    key                  = "terraform.tfstate"
  }
}
