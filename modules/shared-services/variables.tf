# ============================================================================
# SHARED SERVICES MODULE - INPUT VARIABLES
# ============================================================================

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "kv_name" {
  description = "Key Vault name"
  type        = string
}

variable "acr_sku" {
  description = "ACR SKU (Basic, Standard, or Premium)"
  type        = string
}

variable "kv_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
}

variable "vnet_id" {
  description = "VNet ID for private endpoints"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
}

variable "aks_dev_identity_id" {
  description = "Dev AKS managed identity principal ID"
  type        = string
}

variable "aks_prod_identity_id" {
  description = "Prod AKS managed identity principal ID"
  type        = string
}

variable "enable_geo_replication" {
  description = "Enable geo-replication for ACR"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
