# Azure App Gateway + VM + k3s Project

terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "local" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "network" {
  name     = "rg-network"
  location = "eastus"
}
