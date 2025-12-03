# ============================================================================
# AKS MODULE - INPUT VARIABLES
# ============================================================================

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
}

variable "vnet_id" {
  description = "VNet ID"
  type        = string
}

variable "aks_subnet_id" {
  description = "AKS subnet ID"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "node_size" {
  description = "VM size for nodes"
  type        = string
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling"
  type        = bool
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
}

variable "availability_zones" {
  description = "Availability zones for nodes"
  type        = list(string)
}

variable "identity_id" {
  description = "User-assigned managed identity ID"
  type        = string
}

variable "identity_principal_id" {
  description = "User-assigned managed identity principal ID"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
