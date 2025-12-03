terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # If running in CI using the AZURE_CREDENTIALS (sdk-auth) secret, no further config is required.
  # If running locally without env auth, you can uncomment and set these:
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
}
