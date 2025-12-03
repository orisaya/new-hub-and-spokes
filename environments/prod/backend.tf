# ============================================================================
# BACKEND CONFIGURATION - PRODUCTION ENVIRONMENT
# ============================================================================
# This file configures where Terraform stores state for the PROD environment
#
# This file is located in environments/prod/ and will be automatically used
# when you run terraform commands with -backend-config flag

terraform {
  backend "azurerm" {
    # Resource group where state storage account lives
    resource_group_name = "rg-terraform-state"

    # Storage account name (must be globally unique)
    # Replace with your actual storage account name
    storage_account_name = "tfstateXXXXXXXX"

    # Container name for blob storage
    container_name = "tfstate"

    # State file name for PROD environment
    key = "hub-spoke-prod.tfstate"

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
#    From project root:
#    - terraform init -backend-config=environments/prod/backend.tf
#    Or use Makefile:
#    - make init-prod
#
# 5. DEPLOYMENT:
#    - terraform plan -var-file=environments/prod/terraform.tfvars
#    - terraform apply -var-file=environments/prod/terraform.tfvars
#    Or use Makefile:
#    - make prod-plan
#    - make prod-apply
#
# 6. PRODUCTION CONSIDERATIONS:
#    - Consider using a separate storage account for prod state
#    - Enable versioning on the storage account (already enabled by create-backend.sh)
#    - Restrict access to prod state files via RBAC
#    - Consider enabling soft delete for blob storage
#    - Set up monitoring and alerts for state file access
