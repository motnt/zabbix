# Backend configuration for Terraform state
# Uncomment and configure the backend below for production use

/*
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateumbraco"
    container_name       = "tfstate"
    key                  = "umbraco.terraform.tfstate"
  }
}
*/

# For local development, state is stored locally
# For production, uncomment the backend configuration above and create the storage account