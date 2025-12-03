#!/bin/bash
# ============================================================================
# Deploy Azure Hub-and-Spoke Infrastructure
# ============================================================================
# Usage: ./scripts/deploy.sh [dev|prod]

set -e  # Exit on any error

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get environment from argument
ENVIRONMENT=${1:-dev}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Use 'dev' or 'prod'${NC}"
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Azure Hub-and-Spoke Deployment${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}terraform is required but not installed.${NC}" >&2; exit 1; }
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI is required but not installed.${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Check Azure login
echo -e "${BLUE}Step 2: Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Please login:${NC}"
    az login
fi
echo -e "${GREEN}Current subscription:${NC}"
az account show --query "{Name:name, ID:id}" -o table
echo ""

# Confirm subscription
read -p "Continue with this subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Configure backend
echo -e "${BLUE}Step 3: Configuring backend for ${ENVIRONMENT}...${NC}"
if [ -f backend.tf ]; then
    echo -e "${YELLOW}Existing backend.tf found${NC}"
    read -p "Replace with ${ENVIRONMENT} backend? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "environments/backend-${ENVIRONMENT}.tf" backend.tf
        echo -e "${GREEN}✓ Backend configured for ${ENVIRONMENT}${NC}"
    fi
else
    cp "environments/backend-${ENVIRONMENT}.tf" backend.tf
    echo -e "${GREEN}✓ Backend configured for ${ENVIRONMENT}${NC}"
fi
echo -e "${YELLOW}Make sure to update storage_account_name in backend.tf!${NC}"
echo ""

# Initialize Terraform
echo -e "${BLUE}Step 4: Initializing Terraform...${NC}"
terraform init
echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Validate configuration
echo -e "${BLUE}Step 5: Validating configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Format code
echo -e "${BLUE}Step 6: Formatting code...${NC}"
terraform fmt -recursive
echo -e "${GREEN}✓ Code formatted${NC}"
echo ""

# Generate plan
echo -e "${BLUE}Step 7: Generating execution plan...${NC}"
terraform plan -var-file="environments/${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"
echo -e "${GREEN}✓ Plan generated${NC}"
echo ""

# Estimate time
if [ "$ENVIRONMENT" = "prod" ]; then
    ESTIMATE="20-25 minutes"
else
    ESTIMATE="15-20 minutes"
fi

# Confirm deployment
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}READY TO DEPLOY${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Environment: $ENVIRONMENT"
echo "Estimated time: $ESTIMATE"
echo ""

if [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${RED}WARNING: You are deploying to PRODUCTION!${NC}"
    echo ""
    read -p "Type 'DEPLOY-PROD' to confirm: " -r
    if [[ ! $REPLY = "DEPLOY-PROD" ]]; then
        echo -e "${YELLOW}Deployment cancelled.${NC}"
        exit 0
    fi
else
    read -p "Deploy now? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deployment cancelled.${NC}"
        exit 0
    fi
fi

# Apply plan
echo ""
echo -e "${BLUE}Step 8: Applying configuration...${NC}"
echo -e "${YELLOW}This will take approximately $ESTIMATE${NC}"
echo ""

START_TIME=$(date +%s)
terraform apply "${ENVIRONMENT}.tfplan"
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT SUCCESSFUL! 🎉${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Deployment time: ${MINUTES}m ${SECONDS}s"
echo ""

# Show outputs
echo -e "${BLUE}Important outputs:${NC}"
terraform output quick_reference

# Post-deployment steps
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Get AKS credentials:"
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "   az aks get-credentials --resource-group rg-hubspoke-dev-uks-dev --name aks-hubspoke-dev-uks-dev"
else
    echo "   az aks get-credentials --resource-group rg-hubspoke-prod-uks-prod --name aks-hubspoke-prod-uks-prod"
fi
echo ""
echo "2. Verify cluster:"
echo "   kubectl get nodes"
echo ""
echo "3. Login to ACR:"
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "   az acr login --name acrhubspokedevuks"
else
    echo "   az acr login --name acrhubspokeprodprod"
fi
echo ""

# Save deployment info
echo "Deployment completed at $(date)" > ".deployment-${ENVIRONMENT}.log"
echo "Duration: ${MINUTES}m ${SECONDS}s" >> ".deployment-${ENVIRONMENT}.log"

echo -e "${GREEN}Deployment log saved to .deployment-${ENVIRONMENT}.log${NC}"
