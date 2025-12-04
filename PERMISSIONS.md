# Azure RBAC Permissions for Terraform Deployment

## Overview

This document explains the Azure permissions required to deploy this infrastructure and how to resolve authorization errors related to role assignments.

## The Authorization Error

If you encounter this error during deployment:

```
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request: StatusCode=403
Code="AuthorizationFailed"
Message="The client with object id 'xxx' does not have authorization to perform action
'Microsoft.Authorization/roleAssignments/write'"
```

This means the service principal or managed identity running Terraform doesn't have sufficient permissions to create role assignments.

## Understanding Azure RBAC Roles

Azure has built-in roles with different capabilities:

- **Owner**: Full access including the ability to manage role assignments
- **User Access Administrator**: Can manage role assignments but not resources
- **Contributor**: Can manage resources but **CANNOT** create role assignments
- **Reader**: Read-only access

## Solutions

### Option 1: Skip Role Assignments (Recommended for Limited Permissions)

If you don't have permissions to create role assignments, you can skip them during deployment and create them manually later:

1. **Set the variable to skip role assignments:**

   Edit your `environments/dev/terraform.tfvars` or `environments/prod/terraform.tfvars`:

   ```hcl
   create_role_assignments = false
   ```

2. **Deploy with Terraform:**

   ```bash
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

3. **Manually create the role assignments after deployment** (see below)

### Option 2: Grant Proper Permissions (Recommended for Production)

Ask your Azure administrator to grant the service principal one of these roles:

#### For Subscription-Level Deployment:

```bash
# Get your service principal ID
SP_ID=$(az ad sp list --display-name "your-sp-name" --query "[0].id" -o tsv)

# Option A: Grant User Access Administrator (can manage RBAC only)
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Option B: Grant Owner (full access - use with caution)
az role assignment create \
  --assignee $SP_ID \
  --role "Owner" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

#### For Resource Group-Level Deployment:

```bash
# Grant User Access Administrator on specific resource groups
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-dev"

az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-prod"

az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-shared"
```

### Option 3: Enable Role Assignments Later

If you deployed with `create_role_assignments = false`, you can enable them later:

1. **Grant the required permissions** (see Option 2 above)

2. **Update your tfvars:**

   ```hcl
   create_role_assignments = true
   ```

3. **Apply the changes:**

   ```bash
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

## Manual Role Assignment Creation

If you skip role assignments during Terraform deployment, create them manually:

### 1. Get the Managed Identity Principal IDs

```bash
# Dev AKS Identity
DEV_MI_ID=$(az identity show \
  --name mi-hubspoke-dev-weu-aks-dev \
  --resource-group rg-hubspoke-dev-weu-dev \
  --query principalId -o tsv)

# Prod AKS Identity
PROD_MI_ID=$(az identity show \
  --name mi-hubspoke-dev-weu-aks-prod \
  --resource-group rg-hubspoke-dev-weu-prod \
  --query principalId -o tsv)
```

### 2. Create Role Assignments

```bash
# Network Contributor for Dev AKS
az role assignment create \
  --assignee $DEV_MI_ID \
  --role "Network Contributor" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-dev"

# Network Contributor for Prod AKS
az role assignment create \
  --assignee $PROD_MI_ID \
  --role "Network Contributor" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-prod"

# Reader on Shared Services for Dev AKS
az role assignment create \
  --assignee $DEV_MI_ID \
  --role "Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-shared"

# Reader on Shared Services for Prod AKS
az role assignment create \
  --assignee $PROD_MI_ID \
  --role "Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-hubspoke-dev-weu-shared"

# Managed Identity Operator for Dev AKS (on its own identity)
DEV_MI_RESOURCE_ID=$(az identity show \
  --name mi-hubspoke-dev-weu-aks-dev \
  --resource-group rg-hubspoke-dev-weu-dev \
  --query id -o tsv)

az role assignment create \
  --assignee $DEV_MI_ID \
  --role "Managed Identity Operator" \
  --scope "$DEV_MI_RESOURCE_ID"

# Managed Identity Operator for Prod AKS (on its own identity)
PROD_MI_RESOURCE_ID=$(az identity show \
  --name mi-hubspoke-dev-weu-aks-prod \
  --resource-group rg-hubspoke-dev-weu-prod \
  --query id -o tsv)

az role assignment create \
  --assignee $PROD_MI_ID \
  --role "Managed Identity Operator" \
  --scope "$PROD_MI_RESOURCE_ID"
```

## Role Assignments Explained

The security module creates these role assignments:

| Role | Identity | Scope | Purpose |
|------|----------|-------|---------|
| Network Contributor | Dev AKS MI | Dev Resource Group | Allows AKS to manage network resources (load balancers, IPs) |
| Network Contributor | Prod AKS MI | Prod Resource Group | Allows AKS to manage network resources |
| Reader | Dev AKS MI | Shared Resource Group | Allows Dev AKS to read shared services metadata |
| Reader | Prod AKS MI | Shared Resource Group | Allows Prod AKS to read shared services metadata |
| Managed Identity Operator | Dev AKS MI | Dev AKS MI | Allows AKS control plane to assign kubelet identity |
| Managed Identity Operator | Prod AKS MI | Prod AKS MI | Allows AKS control plane to assign kubelet identity |

## For CI/CD Pipelines

When using GitHub Actions or Azure DevOps:

### GitHub Actions with OIDC

Ensure your Azure AD App Registration has the required role:

```bash
# Get the app ID
APP_ID=$(az ad app list --display-name "github-oidc-app" --query "[0].appId" -o tsv)

# Create service principal if needed
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# Grant User Access Administrator
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### Azure DevOps Service Connection

1. Navigate to **Project Settings** → **Service connections**
2. Edit your Azure Resource Manager connection
3. Ask your admin to grant "User Access Administrator" role to the service principal
4. Or set `create_role_assignments = false` in your pipeline variables

## Troubleshooting

### Check Current Permissions

```bash
# List role assignments for your service principal
az role assignment list \
  --assignee YOUR_SP_OBJECT_ID \
  --all \
  --output table
```

### Verify Service Principal Identity

```bash
# For Azure CLI login
az account show

# For service principal
az ad sp show --id YOUR_SP_OBJECT_ID
```

### Test Permissions

```bash
# Test if you can create a role assignment
az role assignment create \
  --assignee YOUR_SP_OBJECT_ID \
  --role "Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/test-rg" \
  --dry-run
```

## Best Practices

1. **Principle of Least Privilege**: Only grant "User Access Administrator" at the resource group level if possible
2. **Separate Deployments**: Consider separating infrastructure deployment from role assignment creation
3. **Audit Regularly**: Review role assignments periodically
4. **Use Managed Identities**: Prefer managed identities over service principals when possible
5. **Document Permissions**: Keep track of which identities have which permissions

## References

- [Azure built-in roles](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Assign Azure roles using Azure CLI](https://docs.microsoft.com/azure/role-based-access-control/role-assignments-cli)
- [Best practices for Azure RBAC](https://docs.microsoft.com/azure/role-based-access-control/best-practices)
