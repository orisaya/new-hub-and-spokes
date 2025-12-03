# ============================================================================
# FIREWALL MODULE - OUTPUTS
# ============================================================================

output "firewall_id" {
  description = "Azure Firewall ID"
  value       = azurerm_firewall.main.id
}

output "firewall_name" {
  description = "Azure Firewall name"
  value       = azurerm_firewall.main.name
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address (used for routing)"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP address"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "Firewall policy ID"
  value       = azurerm_firewall_policy.main.id
}
