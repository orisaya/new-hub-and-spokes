# ============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# ============================================================================
# This file contains all settings specific to the DEV environment
# Use this file: terraform plan -var-file="environments/dev.tfvars"

# -----------------------------------------------------------------------------
# GENERAL SETTINGS
# -----------------------------------------------------------------------------
environment  = "dev"
location     = "westeurope"
project_name = "hubspoke"

# Tags for all resources in dev
tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
  Project     = "HubSpoke"
  CostCenter  = "Engineering"
  Owner       = "DevOps Team"
}

# -----------------------------------------------------------------------------
# NETWORK SETTINGS
# -----------------------------------------------------------------------------
# Using default address spaces from variables.tf:
# - Hub: 10.0.0.0/16
# - Dev: 10.1.0.0/16
# - Prod: 10.2.0.0/16
# - Shared: 10.3.0.0/16

# -----------------------------------------------------------------------------
# FIREWALL SETTINGS
# -----------------------------------------------------------------------------
firewall_sku_tier    = "Basic" # Basic tier for dev (lower cost)
enable_firewall_logs = true

# -----------------------------------------------------------------------------
# AKS SETTINGS
# -----------------------------------------------------------------------------
aks_kubernetes_version = "1.28" # Update to latest stable version

# Dev cluster settings (smaller for cost savings)
dev_aks_node_count = 2                 # 2 nodes for dev
dev_aks_node_size  = "Standard_D2s_v3" # Small VMs (2 vCPU, 8 GB RAM)

# Prod cluster settings (not used in dev deployment, but required)
prod_aks_node_count = 3
prod_aks_node_size  = "Standard_D4s_v3"

# Auto-scaling settings
enable_aks_auto_scaling = true
aks_min_node_count      = 1 # Scale down to 1 node when idle
aks_max_node_count      = 5 # Scale up to 5 nodes max

# -----------------------------------------------------------------------------
# SHARED SERVICES SETTINGS
# -----------------------------------------------------------------------------
acr_sku                    = "Standard" # Standard tier for dev
key_vault_sku              = "standard" # Standard tier
enable_acr_geo_replication = false      # No geo-replication in dev

# -----------------------------------------------------------------------------
# SECURITY SETTINGS
# -----------------------------------------------------------------------------
enable_azure_policy      = true # Enable policies even in dev
enable_private_endpoints = true # Use private endpoints
allowed_ssh_sources      = []   # No direct SSH access

# -----------------------------------------------------------------------------
# MONITORING SETTINGS
# -----------------------------------------------------------------------------
enable_log_analytics = true
log_retention_days   = 30 # Keep logs for 30 days in dev
