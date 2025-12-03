# ============================================================================
# TERRAFORM AND PROVIDER VERSIONS
# ============================================================================
# This file specifies which versions of Terraform and Azure provider we use
# Think of it as saying "I need these tools with these specific versions"

terraform {
  # We need Terraform version 1.6 or higher
  required_version = ">= 1.6.0"

  # Backend configuration is environment-specific
  # Located in environments/dev/backend.tf and environments/prod/backend.tf
  # Use: terraform init -backend-config=environments/dev/backend.tf

  # Required providers (like apps we need installed)
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80" # Use version 3.80 or higher
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Configure the Azure Provider
# This is like logging into Azure so we can create resources
provider "azurerm" {
  features {
    # Enable key vault purge protection features
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    # Enable resource group management features
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
