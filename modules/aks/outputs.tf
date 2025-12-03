# ============================================================================
# AKS MODULE - OUTPUTS
# ============================================================================

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "AKS cluster private FQDN"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "node_resource_group" {
  description = "Node resource group name (managed by AKS)"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kubelet_identity" {
  description = "Kubelet identity"
  value = {
    client_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  }
}
