# ============================================================================
# NETWORKING MODULE - OUTPUTS
# ============================================================================
# These outputs provide information about the networks we created

# -----------------------------------------------------------------------------
# HUB VNET OUTPUTS
# -----------------------------------------------------------------------------

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "Firewall subnet ID"
  value       = azurerm_subnet.firewall.id
}

output "firewall_management_subnet_id" {
  description = "Firewall management subnet ID"
  value       = azurerm_subnet.firewall_management.id
}

# -----------------------------------------------------------------------------
# DEV SPOKE VNET OUTPUTS
# -----------------------------------------------------------------------------

output "dev_vnet_id" {
  description = "Dev spoke VNet ID"
  value       = azurerm_virtual_network.dev.id
}

output "dev_vnet_name" {
  description = "Dev spoke VNet name"
  value       = azurerm_virtual_network.dev.name
}

output "dev_aks_subnet_id" {
  description = "Dev AKS subnet ID"
  value       = azurerm_subnet.dev_aks.id
}

output "dev_private_endpoint_subnet_id" {
  description = "Dev private endpoint subnet ID"
  value       = azurerm_subnet.dev_private_endpoint.id
}

# -----------------------------------------------------------------------------
# PROD SPOKE VNET OUTPUTS
# -----------------------------------------------------------------------------

output "prod_vnet_id" {
  description = "Prod spoke VNet ID"
  value       = azurerm_virtual_network.prod.id
}

output "prod_vnet_name" {
  description = "Prod spoke VNet name"
  value       = azurerm_virtual_network.prod.name
}

output "prod_aks_subnet_id" {
  description = "Prod AKS subnet ID"
  value       = azurerm_subnet.prod_aks.id
}

output "prod_private_endpoint_subnet_id" {
  description = "Prod private endpoint subnet ID"
  value       = azurerm_subnet.prod_private_endpoint.id
}

# -----------------------------------------------------------------------------
# SHARED SPOKE VNET OUTPUTS
# -----------------------------------------------------------------------------

output "shared_vnet_id" {
  description = "Shared spoke VNet ID"
  value       = azurerm_virtual_network.shared.id
}

output "shared_vnet_name" {
  description = "Shared spoke VNet name"
  value       = azurerm_virtual_network.shared.name
}

output "shared_services_subnet_id" {
  description = "Shared services subnet ID"
  value       = azurerm_subnet.shared_services.id
}

output "shared_private_endpoint_subnet_id" {
  description = "Shared private endpoint subnet ID"
  value       = azurerm_subnet.shared_private_endpoint.id
}

# -----------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
# -----------------------------------------------------------------------------

output "dev_route_table_id" {
  description = "Dev route table ID"
  value       = azurerm_route_table.dev.id
}

output "prod_route_table_id" {
  description = "Prod route table ID"
  value       = azurerm_route_table.prod.id
}

output "shared_route_table_id" {
  description = "Shared route table ID"
  value       = azurerm_route_table.shared.id
}
