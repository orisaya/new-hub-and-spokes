# ============================================================================
# OUTPUTS
# ============================================================================
# These are the important values you'll get after deployment
# Think of them as the "results" or "answers" after building everything

# -----------------------------------------------------------------------------
# RESOURCE GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "resource_groups" {
  description = "Resource group information"
  value = {
    hub = {
      name = azurerm_resource_group.hub.name
      id   = azurerm_resource_group.hub.id
    }
    dev = {
      name = azurerm_resource_group.dev.name
      id   = azurerm_resource_group.dev.id
    }
    prod = {
      name = azurerm_resource_group.prod.name
      id   = azurerm_resource_group.prod.id
    }
    shared = {
      name = azurerm_resource_group.shared.name
      id   = azurerm_resource_group.shared.id
    }
  }
}

# -----------------------------------------------------------------------------
# NETWORKING OUTPUTS
# -----------------------------------------------------------------------------

output "networking" {
  description = "Network configuration details"
  value = {
    hub_vnet = {
      id            = module.networking.hub_vnet_id
      name          = module.networking.hub_vnet_name
      address_space = var.hub_vnet_address_space
    }
    dev_vnet = {
      id            = module.networking.dev_vnet_id
      name          = module.networking.dev_vnet_name
      address_space = var.dev_spoke_vnet_address_space
    }
    prod_vnet = {
      id            = module.networking.prod_vnet_id
      name          = module.networking.prod_vnet_name
      address_space = var.prod_spoke_vnet_address_space
    }
    shared_vnet = {
      id            = module.networking.shared_vnet_id
      name          = module.networking.shared_vnet_name
      address_space = var.shared_spoke_vnet_address_space
    }
  }
}

# -----------------------------------------------------------------------------
# FIREWALL OUTPUTS
# -----------------------------------------------------------------------------

output "firewall" {
  description = "Azure Firewall information"
  value = {
    name               = module.firewall.firewall_name
    id                 = module.firewall.firewall_id
    private_ip_address = module.firewall.firewall_private_ip
    public_ip_address  = module.firewall.firewall_public_ip
  }
}

# -----------------------------------------------------------------------------
# AKS OUTPUTS
# -----------------------------------------------------------------------------

output "aks_clusters" {
  description = "AKS cluster information"
  value = {
    dev = {
      name                = module.aks_dev.cluster_name
      id                  = module.aks_dev.cluster_id
      fqdn                = module.aks_dev.cluster_fqdn
      node_resource_group = module.aks_dev.node_resource_group
    }
    prod = {
      name                = module.aks_prod.cluster_name
      id                  = module.aks_prod.cluster_id
      fqdn                = module.aks_prod.cluster_fqdn
      node_resource_group = module.aks_prod.node_resource_group
    }
  }
}

# Commands to get AKS credentials (copy-paste these after deployment)
output "aks_commands" {
  description = "Commands to connect to your AKS clusters"
  value = {
    dev_login  = "az aks get-credentials --resource-group ${azurerm_resource_group.dev.name} --name ${local.aks_dev_name}"
    prod_login = "az aks get-credentials --resource-group ${azurerm_resource_group.prod.name} --name ${local.aks_prod_name}"
  }
}

# -----------------------------------------------------------------------------
# SHARED SERVICES OUTPUTS
# -----------------------------------------------------------------------------

output "shared_services" {
  description = "Shared services information"
  value = {
    acr = {
      name         = module.shared_services.acr_name
      id           = module.shared_services.acr_id
      login_server = module.shared_services.acr_login_server
    }
    key_vault = {
      name = module.shared_services.key_vault_name
      id   = module.shared_services.key_vault_id
      uri  = module.shared_services.key_vault_uri
    }
  }
}

# Command to login to ACR (copy-paste after deployment)
output "acr_login_command" {
  description = "Command to login to Azure Container Registry"
  value       = "az acr login --name ${local.acr_name}"
}

# -----------------------------------------------------------------------------
# SECURITY OUTPUTS
# -----------------------------------------------------------------------------

output "managed_identities" {
  description = "Managed identity information"
  value = {
    aks_dev = {
      id           = module.security.aks_dev_identity_id
      principal_id = module.security.aks_dev_identity_principal_id
      client_id    = module.security.aks_dev_identity_client_id
    }
    aks_prod = {
      id           = module.security.aks_prod_identity_id
      principal_id = module.security.aks_prod_identity_principal_id
      client_id    = module.security.aks_prod_identity_client_id
    }
  }
}

# -----------------------------------------------------------------------------
# MONITORING OUTPUTS
# -----------------------------------------------------------------------------

output "monitoring" {
  description = "Monitoring and logging information"
  value = var.enable_log_analytics ? {
    log_analytics_workspace = {
      name = azurerm_log_analytics_workspace.main[0].name
      id   = azurerm_log_analytics_workspace.main[0].id
    }
  } : null
}

# -----------------------------------------------------------------------------
# QUICK REFERENCE
# -----------------------------------------------------------------------------

output "quick_reference" {
  description = "Quick reference guide for common tasks"
  value = <<-EOT

  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║                     DEPLOYMENT SUCCESSFUL! 🎉                             ║
  ╚═══════════════════════════════════════════════════════════════════════════╝

  📋 RESOURCE GROUPS:
     • Hub:    ${azurerm_resource_group.hub.name}
     • Dev:    ${azurerm_resource_group.dev.name}
     • Prod:   ${azurerm_resource_group.prod.name}
     • Shared: ${azurerm_resource_group.shared.name}

  🔥 AZURE FIREWALL:
     • Private IP: ${module.firewall.firewall_private_ip}
     • Public IP:  ${module.firewall.firewall_public_ip}

  ☸️  AKS CLUSTERS:
     • Dev:  ${local.aks_dev_name}
     • Prod: ${local.aks_prod_name}

  🐳 CONTAINER REGISTRY:
     • ACR: ${local.acr_name}.azurecr.io

  🔐 KEY VAULT:
     • KV: ${local.kv_name}

  📝 NEXT STEPS:
     1. Connect to dev AKS:
        az aks get-credentials --resource-group ${azurerm_resource_group.dev.name} --name ${local.aks_dev_name}

     2. Connect to prod AKS:
        az aks get-credentials --resource-group ${azurerm_resource_group.prod.name} --name ${local.aks_prod_name}

     3. Login to ACR:
        az acr login --name ${local.acr_name}

     4. Test connectivity:
        kubectl get nodes

  EOT
}
