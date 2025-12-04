# ============================================================================
# INPUT VARIABLES
# ============================================================================
# These are the inputs you provide when deploying the infrastructure
# Think of them as questions you need to answer before building

# -----------------------------------------------------------------------------
# GENERAL SETTINGS
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, or prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region where resources will be created (e.g., uksouth)"
  type        = string
  default     = "uksouth"
}

variable "project_name" {
  description = "Project name used for naming resources (keep it short and simple)"
  type        = string
  default     = "hubspoke"
}

variable "tags" {
  description = "Tags to apply to all resources (like labels on boxes)"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "HubSpoke"
  }
}

# -----------------------------------------------------------------------------
# NETWORK SETTINGS
# -----------------------------------------------------------------------------

variable "hub_vnet_address_space" {
  description = "Address space for hub VNet (the central network)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dev_spoke_vnet_address_space" {
  description = "Address space for dev spoke VNet (development network)"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "prod_spoke_vnet_address_space" {
  description = "Address space for prod spoke VNet (production network)"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "shared_spoke_vnet_address_space" {
  description = "Address space for shared services spoke VNet"
  type        = list(string)
  default     = ["10.3.0.0/16"]
}

# -----------------------------------------------------------------------------
# FIREWALL SETTINGS
# -----------------------------------------------------------------------------

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier (Basic for dev, Standard for prod)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU must be Basic, Standard, or Premium."
  }
}

variable "enable_firewall_logs" {
  description = "Enable diagnostic logs for Azure Firewall"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# AKS SETTINGS (Kubernetes Clusters)
# -----------------------------------------------------------------------------

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS clusters"
  type        = string
  default     = "1.30" # Using 1.30 as it's widely supported (1.28 is LTS-only)
}

variable "dev_aks_node_count" {
  description = "Number of nodes in dev AKS cluster"
  type        = number
  default     = 2
}

variable "prod_aks_node_count" {
  description = "Number of nodes in prod AKS cluster"
  type        = number
  default     = 3
}

variable "dev_aks_node_size" {
  description = "VM size for dev AKS nodes (smaller for dev)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "prod_aks_node_size" {
  description = "VM size for prod AKS nodes (larger for prod)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "enable_aks_auto_scaling" {
  description = "Enable auto-scaling for AKS node pools"
  type        = bool
  default     = true
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes when auto-scaling"
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes when auto-scaling"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# SHARED SERVICES SETTINGS
# -----------------------------------------------------------------------------

variable "acr_sku" {
  description = "Azure Container Registry SKU (Basic, Standard, or Premium)"
  type        = string
  default     = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "key_vault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "enable_acr_geo_replication" {
  description = "Enable geo-replication for ACR (Premium SKU only)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# SECURITY SETTINGS
# -----------------------------------------------------------------------------

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on for AKS"
  type        = bool
  default     = true
}

variable "allowed_ssh_sources" {
  description = "List of IP addresses allowed to SSH (if needed)"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for PaaS services"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# MONITORING SETTINGS
# -----------------------------------------------------------------------------

variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace for monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}
