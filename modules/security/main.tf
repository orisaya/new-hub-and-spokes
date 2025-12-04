# ============================================================================
# SECURITY MODULE - MAIN CONFIGURATION
# ============================================================================
# This module creates managed identities and assigns permissions
# Think of managed identities as "service accounts" - special identities
# for services to authenticate without passwords

# -----------------------------------------------------------------------------
# MANAGED IDENTITIES
# -----------------------------------------------------------------------------
# These are like "robot accounts" that AKS clusters use to access other services

# Dev AKS managed identity
resource "azurerm_user_assigned_identity" "aks_dev" {
  name                = var.mi_aks_dev_name
  location            = var.location
  resource_group_name = var.resource_group_dev
  tags                = var.tags
}

# Prod AKS managed identity
resource "azurerm_user_assigned_identity" "aks_prod" {
  name                = var.mi_aks_prod_name
  location            = var.location
  resource_group_name = var.resource_group_prod
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# RBAC ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------
# These give permissions to the managed identities
# Think of them as "permission slips" that allow access to resources

# Network Contributor role for dev AKS on its resource group
# This allows AKS to manage network resources
resource "azurerm_role_assignment" "aks_dev_network" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_dev}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_dev.principal_id
}

# Network Contributor role for prod AKS on its resource group
resource "azurerm_role_assignment" "aks_prod_network" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_prod}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_prod.principal_id
}

# Reader role on shared services resource group for dev AKS
# This allows dev AKS to see (but not modify) shared services
resource "azurerm_role_assignment" "aks_dev_shared_reader" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_shared}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks_dev.principal_id
}

# Reader role on shared services resource group for prod AKS
resource "azurerm_role_assignment" "aks_prod_shared_reader" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_shared}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks_prod.principal_id
}

# Managed Identity Operator role for dev AKS on its own identity
# This allows AKS control plane to assign the kubelet identity
resource "azurerm_role_assignment" "aks_dev_mi_operator" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = azurerm_user_assigned_identity.aks_dev.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_dev.principal_id
}

# Managed Identity Operator role for prod AKS on its own identity
resource "azurerm_role_assignment" "aks_prod_mi_operator" {
  count                = var.create_role_assignments ? 1 : 0
  scope                = azurerm_user_assigned_identity.aks_prod.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_prod.principal_id
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------
# Get current Azure subscription information

data "azurerm_client_config" "current" {}
