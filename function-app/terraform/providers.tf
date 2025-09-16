terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.39.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  subscription_id = var.subscription_id
  client_secret   = var.client_secret
}

