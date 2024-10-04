terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.90.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "=3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
  backend "azurerm" {}
}
