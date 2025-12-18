terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  backend "azurerm" {
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.55"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
