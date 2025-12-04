# ============================================================================
# SHARED SERVICES MODULE - MAIN CONFIGURATION
# ============================================================================
# This module creates shared services used by multiple environments
# ACR: Container Registry for storing Docker images
# Key Vault: Secure storage for secrets, keys, and certificates

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# AZURE CONTAINER REGISTRY (ACR)
# -----------------------------------------------------------------------------
# This is where we store our Docker container images
# Think of it as a private Docker Hub for your organization

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identities instead of admin account

  # Enable public network access (will be restricted by private endpoint if enabled)
  public_network_access_enabled = !var.enable_private_endpoints

  # Network rule set (only applies if Premium SKU)
  dynamic "network_rule_set" {
    for_each = var.acr_sku == "Premium" ? [1] : []
    content {
      default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    }
  }

  # Geo-replication (only for Premium SKU)
  dynamic "georeplications" {
    for_each = var.enable_geo_replication && var.acr_sku == "Premium" ? [1] : []
    content {
      location                = "northeurope" # Replicate to North Europe
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AZURE KEY VAULT
# -----------------------------------------------------------------------------
# Secure storage for secrets, keys, and certificates

resource "azurerm_key_vault" "main" {
  name                = var.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.kv_sku

  # Use RBAC for access control (not access policies)
  enable_rbac_authorization = true

  # Security settings
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true # Cannot be disabled once enabled
  soft_delete_retention_days      = 7    # Keep deleted items for 7 days

  # Network settings
  public_network_access_enabled = !var.enable_private_endpoints

  dynamic "network_acls" {
    for_each = var.enable_private_endpoints ? [1] : []
    content {
      default_action = "Deny"
      bypass         = "AzureServices" # Allow trusted Azure services
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# RBAC ASSIGNMENTS FOR ACR
# -----------------------------------------------------------------------------
# Give AKS clusters permission to pull images from ACR

# Dev AKS can pull from ACR
resource "azurerm_role_assignment" "acr_pull_dev" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull" # Permission to pull images
  principal_id         = var.aks_dev_identity_id
}

# Prod AKS can pull from ACR
resource "azurerm_role_assignment" "acr_pull_prod" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_prod_identity_id
}

# -----------------------------------------------------------------------------
# RBAC ASSIGNMENTS FOR KEY VAULT
# -----------------------------------------------------------------------------
# Give AKS clusters permission to read secrets from Key Vault

# Dev AKS can read secrets
resource "azurerm_role_assignment" "kv_secrets_user_dev" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_dev_identity_id
}

# Prod AKS can read secrets
resource "azurerm_role_assignment" "kv_secrets_user_prod" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_prod_identity_id
}

# -----------------------------------------------------------------------------
# PRIVATE DNS ZONES (for private endpoints)
# -----------------------------------------------------------------------------
# These make sure private endpoints can be reached by friendly names

# Private DNS zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link ACR DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "kv" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Key Vault DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "kv-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------
# These create private connections to ACR and Key Vault
# Instead of going over the internet, traffic stays within Azure

# Private endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${var.acr_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.acr_name}"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${var.kv_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.kv_name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }
}
