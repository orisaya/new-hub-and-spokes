# ============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# ============================================================================
# This file contains all settings specific to the PROD environment
# Use this file: terraform plan -var-file="environments/prod.tfvars"

# -----------------------------------------------------------------------------
# GENERAL SETTINGS
# -----------------------------------------------------------------------------
environment  = "prod"
location     = "uksouth"
project_name = "hubspoke"

# Tags for all resources in prod
tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  Project     = "HubSpoke"
  CostCenter  = "Operations"
  Owner       = "Platform Team"
  Criticality = "High"
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
firewall_sku_tier    = "Standard" # Standard tier for prod (more features)
enable_firewall_logs = true

# -----------------------------------------------------------------------------
# AKS SETTINGS
# -----------------------------------------------------------------------------
aks_kubernetes_version = "1.28" # Update to latest stable version

# Dev cluster settings (not used in prod deployment, but required)
dev_aks_node_count = 2
dev_aks_node_size  = "Standard_D2s_v3"

# Prod cluster settings (larger for production workloads)
prod_aks_node_count = 3                 # 3 nodes minimum for HA
prod_aks_node_size  = "Standard_D4s_v3" # Larger VMs (4 vCPU, 16 GB RAM)

# Auto-scaling settings
enable_aks_auto_scaling = true
aks_min_node_count      = 3  # Always keep 3 nodes running
aks_max_node_count      = 10 # Scale up to 10 nodes under load

# -----------------------------------------------------------------------------
# SHARED SERVICES SETTINGS
# -----------------------------------------------------------------------------
acr_sku                    = "Premium" # Premium tier for prod (geo-replication)
key_vault_sku              = "premium" # Premium tier (HSM-backed keys)
enable_acr_geo_replication = true      # Enable geo-replication for DR

# -----------------------------------------------------------------------------
# SECURITY SETTINGS
# -----------------------------------------------------------------------------
enable_azure_policy      = true # Enforce policies in prod
enable_private_endpoints = true # Use private endpoints
allowed_ssh_sources      = []   # No direct SSH access

# -----------------------------------------------------------------------------
# MONITORING SETTINGS
# -----------------------------------------------------------------------------
enable_log_analytics = true
log_retention_days   = 90 # Keep logs for 90 days in prod (compliance)
