# Backend Configuration Guide

This guide explains how to set up and manage Terraform state backends for different environments.

## 🎯 Overview

Each environment (dev, prod) has its own backend configuration file that specifies where Terraform stores state. This approach provides:

- ✅ **Separate state files** for each environment
- ✅ **No accidental cross-environment changes**
- ✅ **Easy switching** between environments
- ✅ **Version control friendly** (backend.tf is in .gitignore)

## 📁 Backend Files

```
environments/
├── backend-dev.tf   # Dev environment backend config
└── backend-prod.tf  # Prod environment backend config

backend.tf           # Active backend (gitignored, copy from above)
backend.tf.example   # Example for reference
```

## 🚀 Quick Start

### Step 1: Create Storage Account

Run the helper script to create Azure Storage for state:

```bash
./scripts/create-backend.sh
```

This will:
- Create a resource group for state storage
- Create a storage account with versioning enabled
- Create a blob container for state files
- Output the storage account name

**Note the storage account name** - you'll need it in the next step!

### Step 2: Configure Backend for Dev

```bash
# Copy dev backend configuration
cp environments/backend-dev.tf backend.tf

# Edit and update storage account name
vim backend.tf
# Change: storage_account_name = "tfstateXXXXXXXX"
# To:     storage_account_name = "tfstate12345678"  # Your actual storage account

# Initialize Terraform
terraform init
```

### Step 3: Configure Backend for Prod

```bash
# Copy prod backend configuration
cp environments/backend-prod.tf backend.tf

# Edit and update storage account name
vim backend.tf
# Change: storage_account_name = "tfstateXXXXXXXX"
# To:     storage_account_name = "tfstate12345678"  # Your actual storage account

# Re-initialize Terraform
terraform init -reconfigure
```

## 🔄 Switching Between Environments

### Method 1: Using Makefile (Recommended)

```bash
# Switch to dev
make init-dev

# Switch to prod
make init-prod
```

### Method 2: Manual

```bash
# Switch to dev
cp environments/backend-dev.tf backend.tf
terraform init -reconfigure

# Switch to prod
cp environments/backend-prod.tf backend.tf
terraform init -reconfigure
```

### Method 3: Using Deployment Script

```bash
# Deploy script automatically configures backend
./scripts/deploy.sh dev   # Configures dev backend
./scripts/deploy.sh prod  # Configures prod backend
```

## 📝 Backend Configuration Details

### Dev Backend (environments/backend-dev.tf)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"
    container_name       = "tfstate"
    key                  = "hub-spoke-dev.tfstate"  # Dev state file
  }
}
```

### Prod Backend (environments/backend-prod.tf)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"
    container_name       = "tfstate"
    key                  = "hub-spoke-prod.tfstate"  # Prod state file
  }
}
```

**Key Differences:**
- Different `key` values ensure separate state files
- Can use same storage account or different ones
- Can use different subscriptions if needed

## 🔐 Authentication Options

### Option 1: Azure CLI (Default, Recommended)

```bash
az login
terraform init
```

**Pros:**
- Easy to use
- No credentials in code
- Uses your Azure identity

### Option 2: Storage Account Key

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"
    container_name       = "tfstate"
    key                  = "hub-spoke-dev.tfstate"
    access_key           = "your-storage-account-key"  # Not recommended
  }
}
```

**Cons:**
- Hard-coded credentials
- Security risk

### Option 3: SAS Token

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"
    container_name       = "tfstate"
    key                  = "hub-spoke-dev.tfstate"
    sas_token           = "?sv=2019-12-12&ss=..."
  }
}
```

**Use case:**
- CI/CD pipelines
- Limited-time access

### Option 4: Managed Identity (CI/CD)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"
    container_name       = "tfstate"
    key                  = "hub-spoke-dev.tfstate"
    use_msi              = true
  }
}
```

**Use case:**
- Azure DevOps
- GitHub Actions with OIDC
- Azure VMs

## 🛡️ State Security Best Practices

### 1. Enable Storage Account Security

```bash
# Enable versioning (done by create-backend.sh)
az storage account blob-service-properties update \
  --account-name tfstateXXXXXXXX \
  --enable-versioning true

# Enable soft delete
az storage blob service-properties update \
  --account-name tfstateXXXXXXXX \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30

# Require secure transfer
az storage account update \
  --name tfstateXXXXXXXX \
  --https-only true \
  --min-tls-version TLS1_2
```

### 2. Restrict Network Access

```bash
# Deny all network access by default
az storage account update \
  --name tfstateXXXXXXXX \
  --default-action Deny

# Allow specific IP ranges
az storage account network-rule add \
  --account-name tfstateXXXXXXXX \
  --ip-address "YOUR-IP-ADDRESS"
```

### 3. Set Up RBAC

```bash
# Grant minimal permissions
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee user@example.com \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/tfstateXXXXXXXX
```

### 4. Enable Logging

```bash
# Enable diagnostic logs
az monitor diagnostic-settings create \
  --name "state-logs" \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/tfstateXXXXXXXX \
  --logs '[{"category": "StorageWrite", "enabled": true}]' \
  --workspace <log-analytics-workspace-id>
```

## 🔧 Troubleshooting

### Issue: "Backend configuration changed"

```bash
# Re-initialize with new backend
terraform init -reconfigure
```

### Issue: "Failed to get existing workspaces"

```bash
# Verify Azure login
az account show

# Check storage account access
az storage account show --name tfstateXXXXXXXX
```

### Issue: "Error locking state"

```bash
# Check for existing lease
az storage blob show \
  --account-name tfstateXXXXXXXX \
  --container-name tfstate \
  --name hub-spoke-dev.tfstate

# Force unlock (DANGEROUS - only if you're sure no one else is running terraform)
terraform force-unlock <lock-id>
```

### Issue: "State file not found"

This is normal for first deployment. Terraform will create it.

### Issue: Wrong environment state

```bash
# Check which state file you're using
cat backend.tf | grep key

# Switch to correct environment
cp environments/backend-dev.tf backend.tf
terraform init -reconfigure
```

## 🔄 State Migration

### From Local to Remote Backend

```bash
# 1. Configure backend
cp environments/backend-dev.tf backend.tf
vim backend.tf  # Update storage account name

# 2. Initialize with migration
terraform init -migrate-state

# 3. Verify
terraform state list
```

### From Remote to Local (Not Recommended)

```bash
# 1. Comment out backend in backend.tf
# 2. Re-initialize
terraform init -migrate-state

# 3. State is now in terraform.tfstate (local)
```

### Between Different Remote Backends

```bash
# 1. Update backend.tf with new backend
# 2. Re-initialize with migration
terraform init -migrate-state -reconfigure
```

## 📊 State Management Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.hub

# Remove resource from state (doesn't delete resource)
terraform state rm azurerm_resource_group.hub

# Move resource in state
terraform state mv azurerm_resource_group.hub azurerm_resource_group.hub_new

# Pull state to local file
terraform state pull > state.json

# Push state from local file (DANGEROUS)
terraform state push state.json
```

## 🔐 Backup and Recovery

### Manual Backup

```bash
# Download state file
az storage blob download \
  --account-name tfstateXXXXXXXX \
  --container-name tfstate \
  --name hub-spoke-dev.tfstate \
  --file backup-$(date +%Y%m%d).tfstate
```

### Restore from Backup

```bash
# Upload state file
az storage blob upload \
  --account-name tfstateXXXXXXXX \
  --container-name tfstate \
  --name hub-spoke-dev.tfstate \
  --file backup-20241203.tfstate \
  --overwrite
```

### Automatic Versioning

State versioning is enabled by default (via create-backend.sh):

```bash
# List versions
az storage blob list \
  --account-name tfstateXXXXXXXX \
  --container-name tfstate \
  --include v

# Download specific version
az storage blob download \
  --account-name tfstateXXXXXXXX \
  --container-name tfstate \
  --name hub-spoke-dev.tfstate \
  --version-id <version-id> \
  --file state-version.tfstate
```

## ✅ Best Practices Checklist

- [ ] Create separate storage account for state (or at minimum, separate container)
- [ ] Enable versioning on storage account
- [ ] Enable soft delete (30 days retention)
- [ ] Use Azure CLI authentication (don't hardcode keys)
- [ ] Keep backend.tf out of version control (.gitignore)
- [ ] Use separate state files per environment (different `key`)
- [ ] Restrict network access to storage account
- [ ] Set up RBAC with minimal permissions
- [ ] Enable diagnostic logging
- [ ] Regular state backups (automated)
- [ ] Document backend configuration
- [ ] Test state recovery procedure

## 📚 Additional Resources

- [Terraform Azure Backend Documentation](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Azure Storage Security Guide](https://docs.microsoft.com/azure/storage/common/storage-security-guide)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)

---

**Remember**: State files contain sensitive information. Always protect them!
