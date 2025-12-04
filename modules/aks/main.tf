# ============================================================================
# AKS MODULE - MAIN CONFIGURATION
# ============================================================================
# This module creates a private Azure Kubernetes Service (AKS) cluster
# Think of AKS as a managed Kubernetes service - Azure handles the control plane

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# AKS CLUSTER
# -----------------------------------------------------------------------------
# The main Kubernetes cluster

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # Private cluster settings (API server not exposed to internet)
  private_cluster_enabled = var.private_cluster_enabled

  # Network settings
  network_profile {
    network_plugin    = "azure"         # Azure CNI (each pod gets an IP from the VNet)
    network_policy    = "azure"         # Azure Network Policy
    service_cidr      = "172.16.0.0/16" # Internal service IPs
    dns_service_ip    = "172.16.0.10"   # Internal DNS IP
    load_balancer_sku = "standard"      # Standard load balancer
  }

  # Default node pool (system node pool - runs system pods)
  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_size
    vnet_subnet_id      = var.aks_subnet_id
    zones               = var.availability_zones
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"

    # Node labels
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
    }

    # Upgrade settings
    upgrade_settings {
      max_surge = "33%" # Upgrade 33% of nodes at a time
    }

    tags = var.tags
  }

  # Identity configuration (user-assigned managed identity)
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Automatically assign kubelet identity (for pulling images, etc.)
  kubelet_identity {
    client_id                 = var.identity_principal_id
    object_id                 = var.identity_principal_id
    user_assigned_identity_id = var.identity_id
  }

  # Azure RBAC for Kubernetes authorization
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true # Use Azure RBAC instead of Kubernetes RBAC
  }

  # Azure Policy add-on (enforces policies on the cluster)
  azure_policy_enabled = var.enable_azure_policy

  # Monitoring with Azure Monitor
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Maintenance window (when automatic updates can occur)
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
  }

  # Security settings
  sku_tier = var.environment == "prod" ? "Standard" : "Free" # Paid tier for prod

  # Enable cluster auto-upgrade
  automatic_channel_upgrade = var.environment == "prod" ? "patch" : "stable"

  tags = var.tags

  # Lifecycle settings
  lifecycle {
    ignore_changes = [
      kubernetes_version,             # Prevent unwanted version changes
      default_node_pool[0].node_count # Ignore if auto-scaling changes count
    ]
  }
}

# -----------------------------------------------------------------------------
# ACR ROLE ASSIGNMENT
# -----------------------------------------------------------------------------
# This is handled in the shared-services module, but we ensure dependency here

# The AKS cluster needs "AcrPull" permission on ACR to pull images
# This is configured in the shared-services module via the managed identity
