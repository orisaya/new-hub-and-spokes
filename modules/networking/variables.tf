# ============================================================================
# NETWORKING MODULE - INPUT VARIABLES
# ============================================================================
# Variables needed by the networking module

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_hub" {
  description = "Resource group name for hub"
  type        = string
}

variable "resource_group_dev" {
  description = "Resource group name for dev"
  type        = string
}

variable "resource_group_prod" {
  description = "Resource group name for prod"
  type        = string
}

variable "resource_group_shared" {
  description = "Resource group name for shared services"
  type        = string
}

# VNet variables
variable "hub_vnet_name" {
  description = "Hub VNet name"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Hub VNet address space"
  type        = list(string)
}

variable "dev_vnet_name" {
  description = "Dev spoke VNet name"
  type        = string
}

variable "dev_vnet_address_space" {
  description = "Dev spoke VNet address space"
  type        = list(string)
}

variable "prod_vnet_name" {
  description = "Prod spoke VNet name"
  type        = string
}

variable "prod_vnet_address_space" {
  description = "Prod spoke VNet address space"
  type        = list(string)
}

variable "shared_vnet_name" {
  description = "Shared spoke VNet name"
  type        = string
}

variable "shared_vnet_address_space" {
  description = "Shared spoke VNet address space"
  type        = list(string)
}

# Subnet variables
variable "hub_subnets" {
  description = "Hub subnets configuration"
  type        = map(string)
}

variable "dev_subnets" {
  description = "Dev subnets configuration"
  type        = map(string)
}

variable "prod_subnets" {
  description = "Prod subnets configuration"
  type        = map(string)
}

variable "shared_subnets" {
  description = "Shared subnets configuration"
  type        = map(string)
}

variable "firewall_private_ip" {
  description = "Azure Firewall private IP address"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
