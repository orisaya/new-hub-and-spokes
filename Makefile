# ============================================================================
# Makefile for Azure Hub-and-Spoke Terraform Project
# ============================================================================
# This makes common Terraform commands easier to run
# Example: make dev-plan    or    make prod-apply

.PHONY: help init validate format lint clean

# Default target - shows help
.DEFAULT_GOAL := help

# Environment variables
ENV ?= dev
REGION ?= uksouth

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

## help: Show this help message
help:
	@echo "$(BLUE)Azure Hub-and-Spoke Terraform - Available Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Setup Commands:$(NC)"
	@echo "  make init-dev             - Initialize with dev backend"
	@echo "  make init-prod            - Initialize with prod backend"
	@echo "  make validate             - Validate Terraform configuration"
	@echo "  make format               - Format Terraform files"
	@echo "  make lint                 - Lint Terraform code"
	@echo ""
	@echo "$(GREEN)Development Environment:$(NC)"
	@echo "  make dev-plan             - Plan dev deployment"
	@echo "  make dev-apply            - Apply dev deployment"
	@echo "  make dev-destroy          - Destroy dev resources"
	@echo "  make dev-output           - Show dev outputs"
	@echo ""
	@echo "$(GREEN)Production Environment:$(NC)"
	@echo "  make prod-plan            - Plan prod deployment"
	@echo "  make prod-apply           - Apply prod deployment"
	@echo "  make prod-destroy         - Destroy prod resources"
	@echo "  make prod-output          - Show prod outputs"
	@echo ""
	@echo "$(GREEN)Utility Commands:$(NC)"
	@echo "  make clean                - Clean Terraform files"
	@echo "  make az-login             - Login to Azure"
	@echo "  make check-prereqs        - Check prerequisites"
	@echo "  make create-backend       - Create state storage backend"
	@echo ""
	@echo "$(YELLOW)Example: make dev-plan$(NC)"

## init: Initialize Terraform (use init-dev or init-prod for environment-specific)
init:
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@if [ ! -f backend.tf ]; then \
		echo "$(YELLOW)Warning: backend.tf not found!$(NC)"; \
		echo "$(YELLOW)Run 'make init-dev' or 'make init-prod' to set up backend$(NC)"; \
	fi
	terraform init

## init-dev: Initialize with dev backend
init-dev:
	@echo "$(BLUE)Setting up dev backend...$(NC)"
	@echo "$(YELLOW)Remember to update storage_account_name in environments/dev/backend.tf!$(NC)"
	terraform init -backend-config=environments/dev/backend.tf -reconfigure
	@echo "$(GREEN)✓ Initialized with dev backend$(NC)"

## init-prod: Initialize with prod backend
init-prod:
	@echo "$(BLUE)Setting up prod backend...$(NC)"
	@echo "$(YELLOW)Remember to update storage_account_name in environments/prod/backend.tf!$(NC)"
	terraform init -backend-config=environments/prod/backend.tf -reconfigure
	@echo "$(GREEN)✓ Initialized with prod backend$(NC)"

## validate: Validate Terraform configuration
validate:
	@echo "$(BLUE)Validating configuration...$(NC)"
	terraform validate

## format: Format all Terraform files
format:
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

## lint: Run tflint (requires tflint to be installed)
lint:
	@echo "$(BLUE)Linting Terraform code...$(NC)"
	@if command -v tflint > /dev/null; then \
		tflint; \
	else \
		echo "$(YELLOW)tflint not installed. Skipping...$(NC)"; \
	fi

## check-prereqs: Check if required tools are installed
check-prereqs:
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@command -v terraform > /dev/null && echo "$(GREEN)✓ Terraform installed$(NC)" || echo "$(RED)✗ Terraform not found$(NC)"
	@command -v az > /dev/null && echo "$(GREEN)✓ Azure CLI installed$(NC)" || echo "$(RED)✗ Azure CLI not found$(NC)"
	@command -v kubectl > /dev/null && echo "$(GREEN)✓ kubectl installed$(NC)" || echo "$(YELLOW)⚠ kubectl not found (optional)$(NC)"

## az-login: Login to Azure
az-login:
	@echo "$(BLUE)Logging into Azure...$(NC)"
	az login
	@echo "$(GREEN)Current subscription:$(NC)"
	az account show --query "{Name:name, ID:id}" -o table

## create-backend: Create Azure Storage backend for state
create-backend:
	@echo "$(BLUE)Creating Terraform state backend...$(NC)"
	@bash scripts/create-backend.sh

# =============================================================================
# DEVELOPMENT ENVIRONMENT TARGETS
# =============================================================================

## dev-plan: Generate execution plan for dev environment
dev-plan: init-dev validate
	@echo "$(BLUE)Planning dev environment deployment...$(NC)"
	terraform plan -var-file="environments/dev/terraform.tfvars" -out=dev.tfplan

## dev-apply: Apply dev environment configuration
dev-apply: dev-plan
	@echo "$(YELLOW)About to deploy dev environment. Press Ctrl+C to cancel...$(NC)"
	@sleep 3
	terraform apply dev.tfplan
	@echo "$(GREEN)Dev environment deployed successfully!$(NC)"
	@make dev-output

## dev-destroy: Destroy dev environment
dev-destroy:
	@echo "$(RED)WARNING: This will destroy all dev resources!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel or wait 5 seconds...$(NC)"
	@sleep 5
	terraform destroy -var-file="environments/dev/terraform.tfvars"

## dev-output: Show dev environment outputs
dev-output:
	@echo "$(BLUE)Dev environment outputs:$(NC)"
	terraform output

## dev-refresh: Refresh dev state
dev-refresh:
	@echo "$(BLUE)Refreshing dev state...$(NC)"
	terraform refresh -var-file="environments/dev/terraform.tfvars"

# =============================================================================
# PRODUCTION ENVIRONMENT TARGETS
# =============================================================================

## prod-plan: Generate execution plan for prod environment
prod-plan: init-prod validate
	@echo "$(BLUE)Planning prod environment deployment...$(NC)"
	terraform plan -var-file="environments/prod/terraform.tfvars" -out=prod.tfplan

## prod-apply: Apply prod environment configuration
prod-apply:
	@echo "$(RED)WARNING: Deploying to PRODUCTION!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel or wait 10 seconds...$(NC)"
	@sleep 10
	@if [ -f prod.tfplan ]; then \
		terraform apply prod.tfplan; \
		echo "$(GREEN)Prod environment deployed successfully!$(NC)"; \
		make prod-output; \
	else \
		echo "$(RED)No plan file found. Run 'make prod-plan' first.$(NC)"; \
		exit 1; \
	fi

## prod-destroy: Destroy prod environment
prod-destroy:
	@echo "$(RED)DANGER: This will destroy ALL production resources!$(NC)"
	@echo "$(YELLOW)Type 'DELETE-PROD' to confirm:$(NC) "
	@read confirm; \
	if [ "$$confirm" = "DELETE-PROD" ]; then \
		terraform destroy -var-file="environments/prod/terraform.tfvars"; \
	else \
		echo "$(GREEN)Cancelled.$(NC)"; \
	fi

## prod-output: Show prod environment outputs
prod-output:
	@echo "$(BLUE)Prod environment outputs:$(NC)"
	terraform output

## prod-refresh: Refresh prod state
prod-refresh:
	@echo "$(BLUE)Refreshing prod state...$(NC)"
	terraform refresh -var-file="environments/prod/terraform.tfvars"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

## clean: Remove Terraform generated files
clean:
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f *.tfplan
	rm -f *.tfstate*
	@echo "$(GREEN)Cleaned!$(NC)"

## graph: Generate dependency graph
graph:
	@echo "$(BLUE)Generating dependency graph...$(NC)"
	terraform graph | dot -Tsvg > graph.svg
	@echo "$(GREEN)Graph saved to graph.svg$(NC)"

## docs: Generate documentation
docs:
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if command -v terraform-docs > /dev/null; then \
		terraform-docs markdown table --output-file TERRAFORM.md .; \
		echo "$(GREEN)Documentation generated!$(NC)"; \
	else \
		echo "$(YELLOW)terraform-docs not installed. Install from: https://terraform-docs.io/$(NC)"; \
	fi

## cost: Estimate costs (requires infracost)
cost:
	@echo "$(BLUE)Estimating costs...$(NC)"
	@if command -v infracost > /dev/null; then \
		infracost breakdown --path .; \
	else \
		echo "$(YELLOW)infracost not installed. Install from: https://www.infracost.io/$(NC)"; \
	fi

# =============================================================================
# AKS QUICK COMMANDS
# =============================================================================

## aks-dev-creds: Get AKS dev credentials
aks-dev-creds:
	@echo "$(BLUE)Getting dev AKS credentials...$(NC)"
	az aks get-credentials --resource-group rg-hubspoke-dev-uks-dev --name aks-hubspoke-dev-uks-dev --overwrite-existing
	kubectl config use-context aks-hubspoke-dev-uks-dev

## aks-prod-creds: Get AKS prod credentials
aks-prod-creds:
	@echo "$(BLUE)Getting prod AKS credentials...$(NC)"
	az aks get-credentials --resource-group rg-hubspoke-prod-uks-prod --name aks-hubspoke-prod-uks-prod --overwrite-existing
	kubectl config use-context aks-hubspoke-prod-uks-prod

## aks-dev-nodes: Show dev AKS nodes
aks-dev-nodes: aks-dev-creds
	kubectl get nodes

## aks-prod-nodes: Show prod AKS nodes
aks-prod-nodes: aks-prod-creds
	kubectl get nodes
