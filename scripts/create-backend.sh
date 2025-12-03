#!/bin/bash
# ============================================================================
# Create Azure Storage Backend for Terraform State
# ============================================================================
# This script creates an Azure Storage Account to store Terraform state
# Run this BEFORE your first terraform init

set -e  # Exit on any error

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Terraform State Backend Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Configuration
RESOURCE_GROUP_NAME="${TF_STATE_RG:-rg-terraform-state}"
LOCATION="${TF_STATE_LOCATION:-uksouth}"
STORAGE_ACCOUNT_NAME="${TF_STATE_SA:-tfstate$(openssl rand -hex 4)}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Location: $LOCATION"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo -e "${BLUE}Checking Azure login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Starting login...${NC}"
    az login
fi

# Show current subscription
echo -e "${GREEN}Current subscription:${NC}"
az account show --query "{Name:name, ID:id, Tenant:tenantId}" -o table
echo ""

read -p "Continue with this subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Create resource group
echo -e "${BLUE}Creating resource group...${NC}"
if az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
    echo -e "${YELLOW}Resource group already exists.${NC}"
else
    az group create \
        --name $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --tags "ManagedBy=Terraform" "Purpose=StateStorage"
    echo -e "${GREEN}✓ Resource group created${NC}"
fi

# Create storage account
echo -e "${BLUE}Creating storage account...${NC}"
if az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME &> /dev/null; then
    echo -e "${YELLOW}Storage account already exists.${NC}"
else
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --kind StorageV2 \
        --tags "ManagedBy=Terraform" "Purpose=StateStorage"
    echo -e "${GREEN}✓ Storage account created${NC}"
fi

# Enable versioning
echo -e "${BLUE}Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --account-name $STORAGE_ACCOUNT_NAME \
    --enable-versioning true \
    --enable-change-feed true \
    --auth-mode login
echo -e "${GREEN}✓ Versioning enabled${NC}"

# Create container
echo -e "${BLUE}Creating blob container...${NC}"
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --auth-mode login \
    --public-access off
echo -e "${GREEN}✓ Container created${NC}"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Backend created successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}Add this to your versions.tf:${NC}"
echo ""
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"hub-spoke-dev.tfstate\"  # Change per environment"
echo "  }"
echo ""
echo -e "${YELLOW}Don't forget to change the 'key' for different environments!${NC}"
echo "Example:"
echo "  - dev:   key = \"hub-spoke-dev.tfstate\""
echo "  - prod:  key = \"hub-spoke-prod.tfstate\""
echo ""
