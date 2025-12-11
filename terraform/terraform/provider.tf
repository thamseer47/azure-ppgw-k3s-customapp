terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform"        # change to your tfstate RG
    storage_account_name = "tfstate<uniquesuffix>"  # created earlier
    container_name       = "tfstate"
    key                  = "azure-ppgw-k3s-customapp.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
