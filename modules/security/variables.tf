# ============================================================================
# SECURITY MODULE - INPUT VARIABLES
# ============================================================================

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_hub" {
  description = "Hub resource group name"
  type        = string
}

variable "resource_group_dev" {
  description = "Dev resource group name"
  type        = string
}

variable "resource_group_prod" {
  description = "Prod resource group name"
  type        = string
}

variable "resource_group_shared" {
  description = "Shared resource group name"
  type        = string
}

variable "mi_aks_dev_name" {
  description = "Dev AKS managed identity name"
  type        = string
}

variable "mi_aks_prod_name" {
  description = "Prod AKS managed identity name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
