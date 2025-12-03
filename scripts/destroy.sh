#!/bin/bash
# ============================================================================
# Destroy Azure Hub-and-Spoke Infrastructure
# ============================================================================
# Usage: ./scripts/destroy.sh [dev|prod]

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

echo -e "${RED}========================================${NC}"
echo -e "${RED}DESTROY Azure Infrastructure${NC}"
echo -e "${RED}Environment: $ENVIRONMENT${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Warning message
echo -e "${RED}⚠️  WARNING ⚠️${NC}"
echo ""
echo "This will PERMANENTLY DELETE all resources in the $ENVIRONMENT environment:"
echo ""
echo "  • Virtual Networks"
echo "  • Azure Firewall"
echo "  • AKS Clusters"
echo "  • Container Registry"
echo "  • Key Vault (with soft delete, recoverable for 7 days)"
echo "  • All data and configurations"
echo ""

# Show what will be destroyed
echo -e "${BLUE}Checking resources to be destroyed...${NC}"
terraform plan -destroy -var-file="environments/${ENVIRONMENT}/terraform.tfvars" | grep -E "Plan:|#"
echo ""

# Extra confirmation for prod
if [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${RED}================================================${NC}"
    echo -e "${RED}YOU ARE ABOUT TO DESTROY PRODUCTION!${NC}"
    echo -e "${RED}================================================${NC}"
    echo ""
    echo "This action is IRREVERSIBLE!"
    echo ""
    read -p "Type 'DELETE-PRODUCTION' to confirm: " -r
    if [[ ! $REPLY = "DELETE-PRODUCTION" ]]; then
        echo -e "${GREEN}Destruction cancelled. Production is safe.${NC}"
        exit 0
    fi
    echo ""
    read -p "Are you ABSOLUTELY SURE? Type 'YES' to confirm: " -r
    if [[ ! $REPLY = "YES" ]]; then
        echo -e "${GREEN}Destruction cancelled. Production is safe.${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}Are you sure you want to destroy the $ENVIRONMENT environment?${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " -r
    if [[ ! $REPLY = "DELETE" ]]; then
        echo -e "${GREEN}Destruction cancelled.${NC}"
        exit 0
    fi
fi

# One more chance to cancel
echo ""
echo -e "${YELLOW}Last chance to cancel! Press Ctrl+C now or wait 10 seconds...${NC}"
for i in {10..1}; do
    echo -n "$i "
    sleep 1
done
echo ""
echo ""

# Destroy resources
echo -e "${BLUE}Starting destruction...${NC}"
echo ""

START_TIME=$(date +%s)
terraform destroy -var-file="environments/${ENVIRONMENT}/terraform.tfvars" -auto-approve
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DESTRUCTION COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Destruction time: ${MINUTES}m ${SECONDS}s"
echo ""

# Post-destruction cleanup
echo -e "${BLUE}Cleaning up local files...${NC}"
rm -f "${ENVIRONMENT}.tfplan"
rm -f ".deployment-${ENVIRONMENT}.log"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Information about recoverable resources
echo -e "${YELLOW}Note about deleted resources:${NC}"
echo ""
echo "• Key Vault: Soft-deleted, recoverable for 7 days"
echo "  To recover: az keyvault recover --name kv-hubspoke-${ENVIRONMENT}-uks"
echo ""
echo "• ACR: Permanently deleted (not recoverable)"
echo "• AKS: Permanently deleted (not recoverable)"
echo "• VNets: Permanently deleted (not recoverable)"
echo ""

# Save destruction log
echo "Destruction completed at $(date)" > ".destruction-${ENVIRONMENT}.log"
echo "Duration: ${MINUTES}m ${SECONDS}s" >> ".destruction-${ENVIRONMENT}.log"

echo -e "${GREEN}Destruction log saved to .destruction-${ENVIRONMENT}.log${NC}"
