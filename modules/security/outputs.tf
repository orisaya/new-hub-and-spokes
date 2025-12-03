# ============================================================================
# SECURITY MODULE - OUTPUTS
# ============================================================================

# Dev AKS managed identity outputs
output "aks_dev_identity_id" {
  description = "Dev AKS managed identity resource ID"
  value       = azurerm_user_assigned_identity.aks_dev.id
}

output "aks_dev_identity_principal_id" {
  description = "Dev AKS managed identity principal ID (for RBAC)"
  value       = azurerm_user_assigned_identity.aks_dev.principal_id
}

output "aks_dev_identity_client_id" {
  description = "Dev AKS managed identity client ID"
  value       = azurerm_user_assigned_identity.aks_dev.client_id
}

# Prod AKS managed identity outputs
output "aks_prod_identity_id" {
  description = "Prod AKS managed identity resource ID"
  value       = azurerm_user_assigned_identity.aks_prod.id
}

output "aks_prod_identity_principal_id" {
  description = "Prod AKS managed identity principal ID (for RBAC)"
  value       = azurerm_user_assigned_identity.aks_prod.principal_id
}

output "aks_prod_identity_client_id" {
  description = "Prod AKS managed identity client ID"
  value       = azurerm_user_assigned_identity.aks_prod.client_id
}
