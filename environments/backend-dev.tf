# ============================================================================
# BACKEND CONFIGURATION - DEVELOPMENT ENVIRONMENT
# ============================================================================
# This file configures where Terraform stores state for the DEV environment
#
# IMPORTANT: Copy this file to the root directory as "backend.tf" before
# running terraform init for the dev environment
#
# Command: cp environments/backend-dev.tf backend.tf

terraform {
  backend "azurerm" {
    # Resource group where state storage account lives
    resource_group_name = "rg-terraform-state"

    # Storage account name (must be globally unique)
    # Replace with your actual storage account name
    storage_account_name = "tfstateXXXXXXXX"

    # Container name for blob storage
    container_name = "tfstate"

    # State file name for DEV environment
    key = "hub-spoke-dev.tfstate"

    # OPTIONAL: Uncomment if you want to use a specific subscription
    # subscription_id = "00000000-0000-0000-0000-000000000000"

    # OPTIONAL: Uncomment to use SAS token authentication
    # sas_token = "?sv=2019-12-12&ss=..."

    # OPTIONAL: Uncomment to use access key authentication
    # access_key = "your-storage-account-access-key"
  }
}

# ============================================================================
# NOTES
# ============================================================================
#
# 1. CREATE BACKEND STORAGE:
#    Run: ./scripts/create-backend.sh
#    This will create the storage account and give you the name to use above
#
# 2. AUTHENTICATION:
#    By default, uses Azure CLI authentication (recommended)
#    Alternative options: SAS token, access key, or managed identity
#
# 3. STATE LOCKING:
#    Azure automatically provides state locking via blob lease
#    No additional configuration needed
#
# 4. BACKEND INITIALIZATION:
#    - Copy this file: cp environments/backend-dev.tf backend.tf
#    - Update storage_account_name with your actual storage account
#    - Run: terraform init
#
# 5. SWITCHING ENVIRONMENTS:
#    To switch from dev to prod:
#    - Run: terraform init -reconfigure
#    - Or delete .terraform directory and re-init
