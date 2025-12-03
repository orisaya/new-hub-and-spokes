# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# ============================================================================
# This is the main file that brings everything together
# It calls all the modules to build our hub-and-spoke architecture

# Think of this file as the "master plan" that coordinates all the pieces

# -----------------------------------------------------------------------------
# RESOURCE GROUPS
# -----------------------------------------------------------------------------
# Resource groups are like folders that hold our Azure resources

# Hub resource group (contains firewall and hub network)
resource "azurerm_resource_group" "hub" {
  name     = local.rg_hub_name
  location = var.location
  tags     = local.common_tags
}

# Dev spoke resource group (contains dev AKS cluster)
resource "azurerm_resource_group" "dev" {
  name     = local.rg_dev_name
  location = var.location
  tags     = local.common_tags
}

# Prod spoke resource group (contains prod AKS cluster)
resource "azurerm_resource_group" "prod" {
  name     = local.rg_prod_name
  location = var.location
  tags     = local.common_tags
}

# Shared services resource group (contains ACR and Key Vault)
resource "azurerm_resource_group" "shared" {
  name     = local.rg_shared_name
  location = var.location
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# LOG ANALYTICS WORKSPACE (for monitoring and logs)
# -----------------------------------------------------------------------------
# This is where all our logs and monitoring data goes
# Think of it as a central logging system

resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_log_analytics ? 1 : 0

  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# NETWORKING MODULE
# -----------------------------------------------------------------------------
# Creates all VNets, subnets, peering, NSGs, and route tables

module "networking" {
  source = "./modules/networking"

  # Basic settings
  location            = var.location
  resource_group_hub  = azurerm_resource_group.hub.name
  resource_group_dev  = azurerm_resource_group.dev.name
  resource_group_prod = azurerm_resource_group.prod.name
  resource_group_shared = azurerm_resource_group.shared.name

  # VNet settings
  hub_vnet_name           = local.hub_vnet_name
  hub_vnet_address_space  = var.hub_vnet_address_space
  dev_vnet_name           = local.dev_vnet_name
  dev_vnet_address_space  = var.dev_spoke_vnet_address_space
  prod_vnet_name          = local.prod_vnet_name
  prod_vnet_address_space = var.prod_spoke_vnet_address_space
  shared_vnet_name        = local.shared_vnet_name
  shared_vnet_address_space = var.shared_spoke_vnet_address_space

  # Subnet settings
  hub_subnets    = local.hub_subnets
  dev_subnets    = local.dev_subnets
  prod_subnets   = local.prod_subnets
  shared_subnets = local.shared_subnets

  # Firewall IP (will be set after firewall is created)
  firewall_private_ip = module.firewall.firewall_private_ip

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [
    azurerm_resource_group.hub,
    azurerm_resource_group.dev,
    azurerm_resource_group.prod,
    azurerm_resource_group.shared
  ]
}

# -----------------------------------------------------------------------------
# FIREWALL MODULE
# -----------------------------------------------------------------------------
# Creates Azure Firewall with policies and rules

module "firewall" {
  source = "./modules/firewall"

  # Basic settings
  location           = var.location
  resource_group_name = azurerm_resource_group.hub.name

  # Firewall settings
  firewall_name        = local.firewall_name
  firewall_policy_name = local.firewall_policy_name
  firewall_pip_name    = local.firewall_pip_name
  firewall_sku_tier    = local.firewall_sku

  # Network settings
  firewall_subnet_id            = module.networking.firewall_subnet_id
  firewall_management_subnet_id = module.networking.firewall_management_subnet_id

  # Monitoring
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
  enable_logs                = var.enable_firewall_logs

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [module.networking]
}

# -----------------------------------------------------------------------------
# SECURITY MODULE
# -----------------------------------------------------------------------------
# Creates managed identities and RBAC assignments

module "security" {
  source = "./modules/security"

  # Basic settings
  location            = var.location
  resource_group_hub  = azurerm_resource_group.hub.name
  resource_group_dev  = azurerm_resource_group.dev.name
  resource_group_prod = azurerm_resource_group.prod.name
  resource_group_shared = azurerm_resource_group.shared.name

  # Managed identity names
  mi_aks_dev_name  = local.mi_aks_dev_name
  mi_aks_prod_name = local.mi_aks_prod_name

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [
    azurerm_resource_group.hub,
    azurerm_resource_group.dev,
    azurerm_resource_group.prod,
    azurerm_resource_group.shared
  ]
}

# -----------------------------------------------------------------------------
# SHARED SERVICES MODULE
# -----------------------------------------------------------------------------
# Creates ACR, Key Vault, private endpoints, and DNS zones

module "shared_services" {
  source = "./modules/shared-services"

  # Basic settings
  location           = var.location
  resource_group_name = azurerm_resource_group.shared.name

  # Service names
  acr_name = local.acr_name
  kv_name  = local.kv_name

  # SKU settings
  acr_sku = var.acr_sku
  kv_sku  = var.key_vault_sku

  # Network settings
  vnet_id                      = module.networking.shared_vnet_id
  private_endpoint_subnet_id   = module.networking.shared_private_endpoint_subnet_id
  enable_private_endpoints     = var.enable_private_endpoints

  # Managed identities (for RBAC)
  aks_dev_identity_id  = module.security.aks_dev_identity_principal_id
  aks_prod_identity_id = module.security.aks_prod_identity_principal_id

  # ACR geo-replication
  enable_geo_replication = var.enable_acr_geo_replication && var.acr_sku == "Premium"

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [
    module.networking,
    module.security
  ]
}

# -----------------------------------------------------------------------------
# AKS MODULE - DEV
# -----------------------------------------------------------------------------
# Creates private AKS cluster for development

module "aks_dev" {
  source = "./modules/aks"

  # Basic settings
  location           = var.location
  resource_group_name = azurerm_resource_group.dev.name
  environment        = "dev"

  # Cluster settings
  cluster_name       = local.aks_dev_name
  kubernetes_version = var.aks_kubernetes_version
  dns_prefix         = "${local.aks_dev_name}-dns"

  # Network settings
  vnet_id                    = module.networking.dev_vnet_id
  aks_subnet_id              = module.networking.dev_aks_subnet_id
  private_cluster_enabled    = true

  # Node pool settings
  node_count              = var.dev_aks_node_count
  node_size               = var.dev_aks_node_size
  enable_auto_scaling     = var.enable_aks_auto_scaling
  min_node_count          = var.aks_min_node_count
  max_node_count          = var.aks_max_node_count
  availability_zones      = local.availability_zones

  # Managed identity
  identity_id             = module.security.aks_dev_identity_id
  identity_principal_id   = module.security.aks_dev_identity_principal_id

  # ACR integration
  acr_id = module.shared_services.acr_id

  # Monitoring
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null

  # Azure Policy
  enable_azure_policy = var.enable_azure_policy

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [
    module.networking,
    module.security,
    module.shared_services
  ]
}

# -----------------------------------------------------------------------------
# AKS MODULE - PROD
# -----------------------------------------------------------------------------
# Creates private AKS cluster for production

module "aks_prod" {
  source = "./modules/aks"

  # Basic settings
  location           = var.location
  resource_group_name = azurerm_resource_group.prod.name
  environment        = "prod"

  # Cluster settings
  cluster_name       = local.aks_prod_name
  kubernetes_version = var.aks_kubernetes_version
  dns_prefix         = "${local.aks_prod_name}-dns"

  # Network settings
  vnet_id                    = module.networking.prod_vnet_id
  aks_subnet_id              = module.networking.prod_aks_subnet_id
  private_cluster_enabled    = true

  # Node pool settings
  node_count              = var.prod_aks_node_count
  node_size               = var.prod_aks_node_size
  enable_auto_scaling     = var.enable_aks_auto_scaling
  min_node_count          = var.aks_min_node_count
  max_node_count          = var.aks_max_node_count
  availability_zones      = local.availability_zones

  # Managed identity
  identity_id             = module.security.aks_prod_identity_id
  identity_principal_id   = module.security.aks_prod_identity_principal_id

  # ACR integration
  acr_id = module.shared_services.acr_id

  # Monitoring
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null

  # Azure Policy
  enable_azure_policy = var.enable_azure_policy

  # Tags
  tags = local.common_tags

  # Dependencies
  depends_on = [
    module.networking,
    module.security,
    module.shared_services
  ]
}
