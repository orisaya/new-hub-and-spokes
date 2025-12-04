# ============================================================================
# NETWORKING MODULE - MAIN CONFIGURATION
# ============================================================================
# This module creates all the virtual networks and connections
# Think of it as building the roads and highways between different areas

# -----------------------------------------------------------------------------
# HUB VIRTUAL NETWORK (The central hub)
# -----------------------------------------------------------------------------
# This is the main network that connects everything together

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_hub
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

# Hub subnets
# Firewall subnet (must be named exactly "AzureFirewallSubnet")
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_hub
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets["firewall"]]
}

# Firewall management subnet (required for Basic SKU)
resource "azurerm_subnet" "firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_hub
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets["firewall_management"]]
}

# Gateway subnet (for future VPN/ExpressRoute use)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_hub
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets["gateway"]]
}

# -----------------------------------------------------------------------------
# DEV SPOKE VIRTUAL NETWORK (Development environment)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "dev" {
  name                = var.dev_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_dev
  address_space       = var.dev_vnet_address_space
  tags                = var.tags
}

# Dev AKS subnet (for Kubernetes nodes and pods)
resource "azurerm_subnet" "dev_aks" {
  name                 = "snet-aks-dev"
  resource_group_name  = var.resource_group_dev
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = [var.dev_subnets["aks"]]
}

# Dev private endpoint subnet
resource "azurerm_subnet" "dev_private_endpoint" {
  name                 = "snet-pe-dev"
  resource_group_name  = var.resource_group_dev
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = [var.dev_subnets["private_endpoint"]]
}

# -----------------------------------------------------------------------------
# PROD SPOKE VIRTUAL NETWORK (Production environment)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "prod" {
  name                = var.prod_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_prod
  address_space       = var.prod_vnet_address_space
  tags                = var.tags
}

# Prod AKS subnet (for Kubernetes nodes and pods)
resource "azurerm_subnet" "prod_aks" {
  name                 = "snet-aks-prod"
  resource_group_name  = var.resource_group_prod
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = [var.prod_subnets["aks"]]
}

# Prod private endpoint subnet
resource "azurerm_subnet" "prod_private_endpoint" {
  name                 = "snet-pe-prod"
  resource_group_name  = var.resource_group_prod
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = [var.prod_subnets["private_endpoint"]]
}

# -----------------------------------------------------------------------------
# SHARED SPOKE VIRTUAL NETWORK (Shared services)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "shared" {
  name                = var.shared_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_shared
  address_space       = var.shared_vnet_address_space
  tags                = var.tags
}

# Shared services subnet (for ACR, Key Vault, etc.)
resource "azurerm_subnet" "shared_services" {
  name                 = "snet-services-shared"
  resource_group_name  = var.resource_group_shared
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [var.shared_subnets["services"]]
}

# Shared private endpoint subnet
resource "azurerm_subnet" "shared_private_endpoint" {
  name                 = "snet-pe-shared"
  resource_group_name  = var.resource_group_shared
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [var.shared_subnets["private_endpoint"]]
}

# -----------------------------------------------------------------------------
# VNET PEERING (Connecting the networks together)
# -----------------------------------------------------------------------------
# Hub-and-spoke topology: Hub connects to all spokes, but spokes don't connect
# to each other (they go through the hub/firewall)

# Hub to Dev peering
resource "azurerm_virtual_network_peering" "hub_to_dev" {
  name                      = "peer-hub-to-dev"
  resource_group_name       = var.resource_group_hub
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.dev.id

  # Allow traffic from hub to dev
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true # Allow firewall to forward traffic
  allow_gateway_transit        = true # Allow hub to provide gateway access
  use_remote_gateways          = false
}

# Dev to Hub peering (reverse direction)
resource "azurerm_virtual_network_peering" "dev_to_hub" {
  name                      = "peer-dev-to-hub"
  resource_group_name       = var.resource_group_dev
  virtual_network_name      = azurerm_virtual_network.dev.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false # Set to true when gateway is added
}

# Hub to Prod peering
resource "azurerm_virtual_network_peering" "hub_to_prod" {
  name                      = "peer-hub-to-prod"
  resource_group_name       = var.resource_group_hub
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.prod.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Prod to Hub peering
resource "azurerm_virtual_network_peering" "prod_to_hub" {
  name                      = "peer-prod-to-hub"
  resource_group_name       = var.resource_group_prod
  virtual_network_name      = azurerm_virtual_network.prod.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Hub to Shared peering
resource "azurerm_virtual_network_peering" "hub_to_shared" {
  name                      = "peer-hub-to-shared"
  resource_group_name       = var.resource_group_hub
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.shared.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Shared to Hub peering
resource "azurerm_virtual_network_peering" "shared_to_hub" {
  name                      = "peer-shared-to-hub"
  resource_group_name       = var.resource_group_shared
  virtual_network_name      = azurerm_virtual_network.shared.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# -----------------------------------------------------------------------------
# NETWORK SECURITY GROUPS (NSGs)
# -----------------------------------------------------------------------------
# Think of these as firewalls for subnets - they control what traffic is allowed

# NSG for Dev AKS subnet
resource "azurerm_network_security_group" "dev_aks" {
  name                = "nsg-aks-dev"
  location            = var.location
  resource_group_name = var.resource_group_dev
  tags                = var.tags
}

# Allow AKS internal traffic
resource "azurerm_network_security_rule" "dev_aks_internal" {
  name                        = "AllowAKSInternal"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.dev_subnets["aks"]
  destination_address_prefix  = var.dev_subnets["aks"]
  resource_group_name         = var.resource_group_dev
  network_security_group_name = azurerm_network_security_group.dev_aks.name
}

# Associate NSG with Dev AKS subnet
resource "azurerm_subnet_network_security_group_association" "dev_aks" {
  subnet_id                 = azurerm_subnet.dev_aks.id
  network_security_group_id = azurerm_network_security_group.dev_aks.id
}

# NSG for Prod AKS subnet
resource "azurerm_network_security_group" "prod_aks" {
  name                = "nsg-aks-prod"
  location            = var.location
  resource_group_name = var.resource_group_prod
  tags                = var.tags
}

# Allow AKS internal traffic
resource "azurerm_network_security_rule" "prod_aks_internal" {
  name                        = "AllowAKSInternal"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.prod_subnets["aks"]
  destination_address_prefix  = var.prod_subnets["aks"]
  resource_group_name         = var.resource_group_prod
  network_security_group_name = azurerm_network_security_group.prod_aks.name
}

# Associate NSG with Prod AKS subnet
resource "azurerm_subnet_network_security_group_association" "prod_aks" {
  subnet_id                 = azurerm_subnet.prod_aks.id
  network_security_group_id = azurerm_network_security_group.prod_aks.id
}

# -----------------------------------------------------------------------------
# ROUTE TABLES (Directing traffic through the firewall)
# -----------------------------------------------------------------------------
# These tell traffic where to go - in our case, through the Azure Firewall

# Route table for Dev spoke
resource "azurerm_route_table" "dev" {
  name                = "rt-dev"
  location            = var.location
  resource_group_name = var.resource_group_dev
  tags                = var.tags

  # Disable BGP route propagation (we control routes manually)
  disable_bgp_route_propagation = false
}

# Route for internet-bound traffic from Dev will be created in root main.tf
# to avoid circular dependency between networking and firewall modules

# Associate route table with Dev AKS subnet
resource "azurerm_subnet_route_table_association" "dev_aks" {
  subnet_id      = azurerm_subnet.dev_aks.id
  route_table_id = azurerm_route_table.dev.id
}

# Route table for Prod spoke
resource "azurerm_route_table" "prod" {
  name                = "rt-prod"
  location            = var.location
  resource_group_name = var.resource_group_prod
  tags                = var.tags

  disable_bgp_route_propagation = false
}

# Route for internet-bound traffic from Prod will be created in root main.tf
# to avoid circular dependency between networking and firewall modules

# Associate route table with Prod AKS subnet
resource "azurerm_subnet_route_table_association" "prod_aks" {
  subnet_id      = azurerm_subnet.prod_aks.id
  route_table_id = azurerm_route_table.prod.id
}

# Route table for Shared spoke
resource "azurerm_route_table" "shared" {
  name                = "rt-shared"
  location            = var.location
  resource_group_name = var.resource_group_shared
  tags                = var.tags

  disable_bgp_route_propagation = false
}

# Route for internet-bound traffic from Shared will be created in root main.tf
# to avoid circular dependency between networking and firewall modules

# Associate route table with Shared services subnet
resource "azurerm_subnet_route_table_association" "shared_services" {
  subnet_id      = azurerm_subnet.shared_services.id
  route_table_id = azurerm_route_table.shared.id
}
