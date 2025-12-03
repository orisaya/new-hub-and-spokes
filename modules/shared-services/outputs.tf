# ============================================================================
# SHARED SERVICES MODULE - OUTPUTS
# ============================================================================

# ACR outputs
output "acr_id" {
  description = "Azure Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.main.login_server
}

# Key Vault outputs
output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# Private endpoint outputs
output "acr_private_endpoint_id" {
  description = "ACR private endpoint ID"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.acr[0].id : null
}

output "kv_private_endpoint_id" {
  description = "Key Vault private endpoint ID"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.kv[0].id : null
}
