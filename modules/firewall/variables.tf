# ============================================================================
# FIREWALL MODULE - INPUT VARIABLES
# ============================================================================

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "firewall_name" {
  description = "Azure Firewall name"
  type        = string
}

variable "firewall_policy_name" {
  description = "Azure Firewall policy name"
  type        = string
}

variable "firewall_pip_name" {
  description = "Firewall public IP name"
  type        = string
}

variable "firewall_sku_tier" {
  description = "Firewall SKU tier (Basic, Standard, or Premium)"
  type        = string
}

variable "firewall_subnet_id" {
  description = "Firewall subnet ID"
  type        = string
}

variable "firewall_management_subnet_id" {
  description = "Firewall management subnet ID (required for Basic SKU)"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "enable_logs" {
  description = "Enable diagnostic logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
