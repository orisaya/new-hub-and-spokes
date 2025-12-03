# ============================================================================
# LOCAL VALUES
# ============================================================================
# These are computed values and naming conventions used throughout the project
# Think of them as shortcuts and rules we follow for naming things consistently

locals {
  # -----------------------------------------------------------------------------
  # NAMING CONVENTIONS (following Azure Cloud Adoption Framework)
  # -----------------------------------------------------------------------------
  # Format: [resource-type]-[project]-[environment]-[region]-[instance]
  # Example: rg-hubspoke-dev-uks-001

  # Short region name (uksouth -> uks)
  region_short = {
    "uksouth"    = "uks"
    "ukwest"     = "ukw"
    "eastus"     = "eus"
    "westeurope" = "weu"
  }
  region_code = lookup(local.region_short, var.location, "uks")

  # Common name prefix (used in all resource names)
  name_prefix = "${var.project_name}-${var.environment}-${local.region_code}"

  # -----------------------------------------------------------------------------
  # RESOURCE GROUP NAMES
  # -----------------------------------------------------------------------------
  rg_hub_name    = "rg-${local.name_prefix}-hub"
  rg_dev_name    = "rg-${local.name_prefix}-dev"
  rg_prod_name   = "rg-${local.name_prefix}-prod"
  rg_shared_name = "rg-${local.name_prefix}-shared"

  # -----------------------------------------------------------------------------
  # NETWORK NAMES
  # -----------------------------------------------------------------------------
  hub_vnet_name    = "vnet-${local.name_prefix}-hub"
  dev_vnet_name    = "vnet-${local.name_prefix}-dev"
  prod_vnet_name   = "vnet-${local.name_prefix}-prod"
  shared_vnet_name = "vnet-${local.name_prefix}-shared"

  # Subnet names
  firewall_subnet_name          = "AzureFirewallSubnet" # Must be exactly this name
  firewall_management_subnet    = "AzureFirewallManagementSubnet"
  aks_dev_subnet_name          = "snet-${local.name_prefix}-aks-dev"
  aks_prod_subnet_name         = "snet-${local.name_prefix}-aks-prod"
  shared_services_subnet_name  = "snet-${local.name_prefix}-shared"
  private_endpoint_subnet_name = "snet-${local.name_prefix}-pe"

  # -----------------------------------------------------------------------------
  # FIREWALL NAMES
  # -----------------------------------------------------------------------------
  firewall_name        = "afw-${local.name_prefix}"
  firewall_policy_name = "afwp-${local.name_prefix}"
  firewall_pip_name    = "pip-${local.name_prefix}-afw"

  # -----------------------------------------------------------------------------
  # AKS NAMES
  # -----------------------------------------------------------------------------
  aks_dev_name  = "aks-${local.name_prefix}-dev"
  aks_prod_name = "aks-${local.name_prefix}-prod"

  # -----------------------------------------------------------------------------
  # SHARED SERVICES NAMES
  # -----------------------------------------------------------------------------
  acr_name = replace("acr${var.project_name}${var.environment}${local.region_code}", "-", "") # ACR names cannot have hyphens
  kv_name  = "kv-${local.name_prefix}"

  # -----------------------------------------------------------------------------
  # SECURITY NAMES
  # -----------------------------------------------------------------------------
  mi_aks_dev_name  = "mi-${local.name_prefix}-aks-dev"
  mi_aks_prod_name = "mi-${local.name_prefix}-aks-prod"

  # -----------------------------------------------------------------------------
  # LOG ANALYTICS
  # -----------------------------------------------------------------------------
  log_analytics_name = "log-${local.name_prefix}"

  # -----------------------------------------------------------------------------
  # COMMON TAGS (applied to all resources)
  # -----------------------------------------------------------------------------
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Location    = var.location
      ManagedBy   = "Terraform"
      Project     = var.project_name
      DeployedAt  = timestamp()
    }
  )

  # -----------------------------------------------------------------------------
  # NETWORK CONFIGURATION
  # -----------------------------------------------------------------------------
  # Subnet address prefixes (calculated from VNet address spaces)
  hub_subnets = {
    firewall            = "10.0.0.0/26"  # 64 IPs for firewall
    firewall_management = "10.0.0.64/26" # 64 IPs for firewall management
    gateway             = "10.0.1.0/24"  # 256 IPs for VPN/ExpressRoute gateway (future use)
  }

  dev_subnets = {
    aks              = "10.1.0.0/20" # 4096 IPs for AKS nodes and pods
    private_endpoint = "10.1.16.0/24" # 256 IPs for private endpoints
  }

  prod_subnets = {
    aks              = "10.2.0.0/20" # 4096 IPs for AKS nodes and pods
    private_endpoint = "10.2.16.0/24" # 256 IPs for private endpoints
  }

  shared_subnets = {
    services         = "10.3.0.0/24"  # 256 IPs for shared services
    private_endpoint = "10.3.1.0/24"  # 256 IPs for private endpoints
  }

  # -----------------------------------------------------------------------------
  # ENVIRONMENT-SPECIFIC SETTINGS
  # -----------------------------------------------------------------------------
  # Different settings for dev vs prod
  is_production = var.environment == "prod"

  # Availability zones (more for prod, less for dev)
  availability_zones = local.is_production ? ["1", "2", "3"] : ["1"]

  # SKU settings based on environment
  firewall_sku = var.environment == "prod" ? "Standard" : "Basic"
}
