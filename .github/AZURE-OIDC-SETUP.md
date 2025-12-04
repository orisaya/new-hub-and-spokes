# Azure OIDC Setup for GitHub Actions

This guide walks you through setting up Azure OpenID Connect (OIDC) authentication for GitHub Actions, allowing secure, passwordless authentication to Azure without storing credentials in GitHub.

## 📋 Prerequisites

- Azure subscription with Owner or User Access Administrator role
- Azure CLI installed
- GitHub repository admin access
- PowerShell or Bash terminal

## 🎯 Benefits of OIDC

✅ **No secrets in GitHub** - No need to store Azure credentials
✅ **Automatic rotation** - Tokens are short-lived and auto-rotated
✅ **Granular permissions** - Limit access to specific resources
✅ **Audit trail** - Track which GitHub workflows accessed Azure

---

## 🚀 Step 1: Create Azure AD Application

### Using Azure CLI

```bash
# Login to Azure
az login

# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
APP_NAME="github-actions-oidc-hubspoke"
REPO_OWNER="your-github-username"  # Replace with your GitHub username/org
REPO_NAME="new-hub-and-spokes"     # Replace with your repo name

# Create Azure AD Application
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

echo "Application ID: $APP_ID"

# Create Service Principal
SP_ID=$(az ad sp create \
  --id $APP_ID \
  --query id -o tsv)

echo "Service Principal ID: $SP_ID"
```

### Using Azure Portal

1. Go to **Azure Active Directory** → **App registrations**
2. Click **New registration**
3. Enter name: `github-actions-oidc-hubspoke`
4. Click **Register**
5. Note the **Application (client) ID**
6. Go to **Certificates & secrets** → **Federated credentials**

---

## 🔑 Step 2: Configure Federated Credentials

You need to create federated credentials for each environment and workflow type.

### For Main Branch (Production)

```bash
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-prod-deployment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':ref:refs/heads/main",
    "description": "Production deployment from main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### For Develop Branch (Development)

```bash
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-dev-deployment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':ref:refs/heads/develop",
    "description": "Development deployment from develop branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### For Pull Requests

```bash
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':pull_request",
    "description": "Pull request validations",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### For Environment-Specific (Recommended)

```bash
# For dev environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-environment-dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':environment:dev",
    "description": "Development environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For prod environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-environment-prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':environment:prod",
    "description": "Production environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

---

## 🎭 Step 3: Assign Azure Roles

The service principal needs permissions to create and manage Azure resources.

### Contributor Role on Subscription

```bash
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### Resource Group Scoped (More Secure)

If you prefer to limit access to specific resource groups:

```bash
# Create resource groups first (if they don't exist)
az group create --name rg-terraform-state --location uksouth
az group create --name rg-hubspoke-dev-uks-hub --location uksouth
az group create --name rg-hubspoke-prod-uks-hub --location uksouth

# Assign Contributor role to each RG
for RG in rg-terraform-state rg-hubspoke-dev-uks-hub rg-hubspoke-prod-uks-hub; do
  az role assignment create \
    --assignee $APP_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG"
done
```

### Storage Account Access (for Terraform State)

```bash
# Replace with your actual storage account name
STATE_STORAGE_ACCOUNT="tfstateXXXXXXXX"

az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/$STATE_STORAGE_ACCOUNT"
```

---

## 🔒 Step 4: Configure GitHub Secrets

### Required Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these **Repository secrets**:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `AZURE_CLIENT_ID` | Application (client) ID | From Azure AD App Registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID | From Azure AD overview |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | `az account show --query id -o tsv` |
| `STATE_STORAGE_ACCOUNT` | Storage account name | Your Terraform state storage account |
| `INFRACOST_API_KEY` | Infracost API key | Get from [infracost.io](https://www.infracost.io/) |

### Get Values

```bash
# Get Tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Get Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get Application ID (if you didn't save it earlier)
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

echo "==================================="
echo "GitHub Secrets Configuration"
echo "==================================="
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "STATE_STORAGE_ACCOUNT: $STATE_STORAGE_ACCOUNT"
echo "==================================="
```

---

## 🌍 Step 5: Configure GitHub Environments

### Create Environments

Go to repository → **Settings** → **Environments**

#### Development Environment

1. Click **New environment**
2. Name: `dev`
3. **Protection rules**: None (auto-deploy)
4. **Environment secrets**: (none needed, uses repository secrets)

#### Production Environment

1. Click **New environment**
2. Name: `prod`
3. **Protection rules**:
   - ✅ **Required reviewers**: Add your team members
   - ✅ **Wait timer**: 0 minutes (or add delay if desired)
   - ⬜ **Branch protection**: (optional) Limit to `main` branch
4. **Environment secrets**: (none needed, uses repository secrets)

#### Production Approval Environment

1. Click **New environment**
2. Name: `prod-approval`
3. **Protection rules**:
   - ✅ **Required reviewers**: Add approvers (platform team leads)
   - ✅ **Wait timer**: 5 minutes (gives time to review)
4. This environment is used specifically for approval gates

#### Production Destroy Approval Environment

1. Click **New environment**
2. Name: `prod-destroy-approval`
3. **Protection rules**:
   - ✅ **Required reviewers**: Add multiple approvers (requires unanimous approval)
   - ✅ **Wait timer**: 10 minutes
   - ⚠️ **Note**: This is for destroy operations only

---

## 🧪 Step 6: Test the Connection

### Test with a Simple Workflow

Create a test file: `.github/workflows/test-oidc.yml`

```yaml
name: Test OIDC Connection

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Azure CLI Test
        run: |
          az account show
          az group list --output table
```

Run this workflow manually to verify OIDC authentication works.

---

## 🔍 Verification Checklist

- [ ] Azure AD Application created
- [ ] Service Principal created
- [ ] Federated credentials configured for:
  - [ ] Main branch
  - [ ] Develop branch
  - [ ] Pull requests
  - [ ] Dev environment
  - [ ] Prod environment
- [ ] Contributor role assigned
- [ ] Storage Blob Data Contributor role assigned (for state)
- [ ] GitHub secrets configured:
  - [ ] AZURE_CLIENT_ID
  - [ ] AZURE_TENANT_ID
  - [ ] AZURE_SUBSCRIPTION_ID
  - [ ] STATE_STORAGE_ACCOUNT
  - [ ] INFRACOST_API_KEY
- [ ] GitHub environments created:
  - [ ] dev
  - [ ] prod
  - [ ] prod-approval
  - [ ] prod-destroy-approval
- [ ] Test workflow runs successfully

---

## 🔧 Troubleshooting

### Error: "AADSTS70021: No matching federated identity record found"

**Solution**: Check that the federated credential subject matches exactly:
- For branch: `repo:OWNER/REPO:ref:refs/heads/BRANCH`
- For environment: `repo:OWNER/REPO:environment:ENV_NAME`
- For PR: `repo:OWNER/REPO:pull_request`

### Error: "Insufficient privileges to complete the operation"

**Solution**: Ensure the service principal has the right role assignments:
```bash
az role assignment list --assignee $APP_ID --output table
```

### Error: "The subscription is not registered to use namespace"

**Solution**: Register required resource providers:
```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
```

---

## 🔐 Security Best Practices

1. ✅ **Use environment-specific credentials** - Different credentials for dev/prod
2. ✅ **Limit role assignments** - Use resource group scope instead of subscription
3. ✅ **Enable audit logging** - Monitor service principal activity
4. ✅ **Regular access reviews** - Review and rotate credentials quarterly
5. ✅ **Use managed identities** - For services running in Azure
6. ✅ **Implement approval gates** - Require manual approval for prod
7. ✅ **Monitor federated credential usage** - Check Azure AD sign-in logs

---

## 📚 Additional Resources

- [Azure OIDC Documentation](https://docs.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [GitHub Actions OIDC](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Login Action](https://github.com/marketplace/actions/azure-login)

---

**Setup Complete!** 🎉

Your GitHub Actions workflows can now securely authenticate to Azure using OIDC without storing any credentials in GitHub.
