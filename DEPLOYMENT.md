# Deployment Guide

This guide walks you through deploying the Azure hub-and-spoke architecture step-by-step.

## 📋 Pre-Deployment Checklist

Before deploying, make sure you have:

- [ ] Azure subscription with Owner or Contributor access
- [ ] Azure CLI installed and logged in
- [ ] Terraform 1.6+ installed
- [ ] kubectl installed (optional, for AKS access)
- [ ] Sufficient quota for the resources (especially VMs and Public IPs)

## 🔐 Step 1: Azure Authentication

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "Your Subscription Name or ID"

# Verify you're using the correct subscription
az account show
```

## 💾 Step 2: Configure Terraform Backend (Recommended)

It's best practice to store Terraform state in Azure Storage.

### Create Storage Account for State

```bash
#!/bin/bash

# Set variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"  # Random suffix
CONTAINER_NAME="tfstate"
LOCATION="uksouth"

# Create resource group
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --kind StorageV2

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

echo "Storage Account: $STORAGE_ACCOUNT_NAME"
```

### Update versions.tf

Edit `versions.tf` and uncomment the backend block:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "tfstateXXXXXXXX"  # Replace with your storage account
  container_name       = "tfstate"
  key                  = "hub-spoke-dev.tfstate"  # Change for each environment
}
```

## 🏗️ Step 3: Initialize Terraform

```bash
# Navigate to project directory
cd new-hub-and-spokes

# Initialize Terraform (downloads providers)
terraform init

# Validate configuration
terraform validate

# Format code (optional but recommended)
terraform fmt -recursive
```

## 📝 Step 4: Review Configuration

### Option A: Use Existing Environment Files

Review and customize the environment files:

```bash
# For dev environment
vim environments/dev.tfvars

# For prod environment
vim environments/prod.tfvars
```

### Option B: Create Custom Configuration

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

## 🔍 Step 5: Plan Deployment

**Always run plan before apply!**

### Development Environment

```bash
# Generate and review execution plan
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# Review the plan carefully
# Look for:
# - Number of resources to be created
# - Resource names and configurations
# - Any unexpected changes
```

### Production Environment

```bash
# Generate production plan
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan

# Review even more carefully for production!
```

## 🚀 Step 6: Apply Configuration

### Deploy Development Environment

```bash
# Apply the plan
terraform apply dev.tfplan

# Or apply directly (will prompt for confirmation)
terraform apply -var-file="environments/dev.tfvars"
```

**⏱️ Deployment Time**: Approximately 15-20 minutes

**What's happening?**
1. Creating resource groups (1 min)
2. Creating VNets and subnets (2-3 min)
3. Creating VNet peering (1 min)
4. Creating Azure Firewall (5-7 min) ⏰
5. Creating managed identities (1 min)
6. Creating ACR and Key Vault (2-3 min)
7. Creating private endpoints (2-3 min)
8. Creating AKS clusters (10-15 min) ⏰
9. Configuring RBAC (1-2 min)

### Deploy Production Environment

```bash
# Apply production configuration
terraform apply -var-file="environments/prod.tfvars"
```

**⏱️ Deployment Time**: Approximately 20-25 minutes (larger nodes take longer)

## ✅ Step 7: Verify Deployment

### Check Resource Groups

```bash
# List all resource groups created
az group list --query "[?contains(name, 'hubspoke')]" --output table
```

### Check AKS Clusters

```bash
# List AKS clusters
az aks list --output table

# Get AKS credentials
az aks get-credentials \
  --resource-group rg-hubspoke-dev-uks-dev \
  --name aks-hubspoke-dev-uks-dev

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A
```

### Check Firewall

```bash
# Get firewall details
az network firewall list --output table

# Check firewall rules
az network firewall policy rule-collection-group list \
  --policy-name afwp-hubspoke-dev-uks \
  --resource-group rg-hubspoke-dev-uks-hub
```

### Check ACR

```bash
# List container registries
az acr list --output table

# Login to ACR
az acr login --name acrhubspokedevuks

# Test push/pull (optional)
docker pull nginx:latest
docker tag nginx:latest acrhubspokedevuks.azurecr.io/nginx:latest
docker push acrhubspokedevuks.azurecr.io/nginx:latest
```

### Check Key Vault

```bash
# List key vaults
az keyvault list --output table

# Check your permissions
az keyvault show --name kv-hubspoke-dev-uks
```

## 🔧 Step 8: Post-Deployment Configuration

### Configure kubectl Context

```bash
# Rename context for easier switching
kubectl config rename-context \
  aks-hubspoke-dev-uks-dev \
  dev

# Switch between contexts
kubectl config use-context dev
```

### Test AKS to ACR Integration

```bash
# Deploy a test pod using ACR image
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-acr
spec:
  containers:
  - name: nginx
    image: acrhubspokedevuks.azurecr.io/nginx:latest
EOF

# Check if pod pulls image successfully
kubectl get pod test-acr
kubectl describe pod test-acr

# Cleanup
kubectl delete pod test-acr
```

### Configure Azure Policy (if enabled)

```bash
# Check policy add-on status
az aks show \
  --resource-group rg-hubspoke-dev-uks-dev \
  --name aks-hubspoke-dev-uks-dev \
  --query "addonProfiles.azurepolicy"
```

## 📊 Step 9: Review Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output aks_commands
terraform output quick_reference
```

## 🔄 Updating the Infrastructure

### Making Changes

1. Edit the configuration files
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

```bash
# Example: Update AKS node count
# Edit environments/dev.tfvars:
# dev_aks_node_count = 3

# Plan the change
terraform plan -var-file="environments/dev.tfvars"

# Apply the change
terraform apply -var-file="environments/dev.tfvars"
```

### Refreshing State

```bash
# Refresh state to match real infrastructure
terraform refresh -var-file="environments/dev.tfvars"
```

## 🗑️ Destroying Resources

**⚠️ WARNING: This will delete EVERYTHING!**

### Development Environment

```bash
# Preview what will be destroyed
terraform plan -destroy -var-file="environments/dev.tfvars"

# Destroy resources
terraform destroy -var-file="environments/dev.tfvars"
```

### Production Environment

```bash
# Destroy production (be very careful!)
terraform destroy -var-file="environments/prod.tfvars"
```

**💡 Tip**: For cost savings without destroying everything, you can scale down AKS:

```bash
# Scale down AKS nodes to 0
az aks scale \
  --resource-group rg-hubspoke-dev-uks-dev \
  --name aks-hubspoke-dev-uks-dev \
  --node-count 0
```

## 🐛 Troubleshooting Deployment

### Issue: Quota Exceeded

```bash
# Check quota usage
az vm list-usage --location uksouth --output table

# Request quota increase
# Go to Azure Portal → Subscriptions → Usage + quotas
```

### Issue: Terraform State Locked

```bash
# Force unlock (only if you're sure no other process is running)
terraform force-unlock <LOCK_ID>
```

### Issue: Provider Registration

```bash
# Register required providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry

# Check registration status
az provider show --namespace Microsoft.ContainerService --query "registrationState"
```

### Issue: AKS Deployment Fails

```bash
# Check AKS events
az aks show --resource-group <rg-name> --name <aks-name> --query "provisioningState"

# Check activity log
az monitor activity-log list --resource-group <rg-name> --max-events 50
```

### Issue: Private Endpoint Connection

```bash
# Check private endpoint status
az network private-endpoint list \
  --resource-group rg-hubspoke-dev-uks-shared \
  --output table

# Check private DNS zones
az network private-dns zone list --output table
```

## 📝 Deployment Checklist

After deployment, verify:

- [ ] All resource groups created
- [ ] VNets created and peered
- [ ] Azure Firewall running and rules configured
- [ ] AKS clusters accessible
- [ ] ACR accessible and integrated with AKS
- [ ] Key Vault accessible
- [ ] Private endpoints working
- [ ] Monitoring enabled
- [ ] Tags applied correctly
- [ ] RBAC permissions configured

## 🔒 Security Post-Deployment

1. **Review RBAC Permissions**
   ```bash
   az role assignment list --resource-group <rg-name> --output table
   ```

2. **Enable Azure Defender**
   ```bash
   az security pricing create --name ContainerRegistry --tier Standard
   az security pricing create --name KeyVaults --tier Standard
   az security pricing create --name KubernetesService --tier Standard
   ```

3. **Configure Firewall Logs**
   - Go to Azure Portal → Firewall → Diagnostic settings
   - Enable all log categories
   - Send to Log Analytics workspace

4. **Set Up Alerts**
   - Configure alerts for firewall rule hits
   - Configure alerts for AKS node health
   - Configure alerts for quota usage

## 📚 Next Steps

1. Deploy sample applications to AKS
2. Configure CI/CD pipelines
3. Set up monitoring dashboards
4. Implement backup policies
5. Configure disaster recovery
6. Document runbooks for operations

## 🆘 Getting Help

- Review logs in Log Analytics workspace
- Check Azure Portal activity logs
- Review Terraform state: `terraform show`
- Check this documentation
- Review Azure documentation

---

**Questions?** Review the main [README.md](README.md) or check the troubleshooting section.
