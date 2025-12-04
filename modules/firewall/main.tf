# ============================================================================
# FIREWALL MODULE - MAIN CONFIGURATION
# ============================================================================
# This module creates the Azure Firewall - the security checkpoint for all traffic
# Think of it as a security guard checking everything that goes in and out

# -----------------------------------------------------------------------------
# PUBLIC IP ADDRESSES
# -----------------------------------------------------------------------------
# Firewalls need public IPs to communicate with the internet

# Main public IP for the firewall
resource "azurerm_public_ip" "firewall" {
  name                = var.firewall_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Management public IP (required for Basic SKU)
resource "azurerm_public_ip" "firewall_management" {
  name                = "${var.firewall_pip_name}-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# FIREWALL POLICY
# -----------------------------------------------------------------------------
# This defines the rules for what traffic is allowed or blocked

resource "azurerm_firewall_policy" "main" {
  name                = var.firewall_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.firewall_sku_tier
  tags                = var.tags

  # DNS settings (only available in Standard and Premium SKU, not Basic)
  dynamic "dns" {
    for_each = var.firewall_sku_tier != "Basic" ? [1] : []
    content {
      proxy_enabled = true # Enable DNS proxy
    }
  }

  # Threat intelligence (available in Standard and Premium)
  threat_intelligence_mode = var.firewall_sku_tier != "Basic" ? "Alert" : "Off"
}

# -----------------------------------------------------------------------------
# FIREWALL POLICY RULE COLLECTION GROUP
# -----------------------------------------------------------------------------
# Groups of rules organized by priority

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  # Network rule collection (Layer 3/4 rules - IP and port based)
  network_rule_collection {
    name     = "NetworkRuleCollection"
    priority = 100
    action   = "Allow"

    # Allow AKS to reach Azure services
    rule {
      name                  = "AllowAzureServices"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"] # Dev and Prod AKS
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "80"]
    }

    # Allow DNS traffic
    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"] # All internal networks
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    # Allow NTP (time sync)
    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    # Allow AKS to ACR
    rule {
      name                  = "AllowAKStoACR"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["10.3.0.0/16"] # Shared services network
      destination_ports     = ["443"]
    }
  }

  # Application rule collection (Layer 7 rules - FQDN based)
  application_rule_collection {
    name     = "ApplicationRuleCollection"
    priority = 200
    action   = "Allow"

    # Allow AKS required FQDNs
    rule {
      name = "AllowAKSRequiredFQDNs"
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16"]

      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }

      # AKS required endpoints
      destination_fqdns = [
        "*.azmk8s.io",                    # AKS management
        "*.blob.core.windows.net",        # Storage
        "*.cdn.mscr.io",                  # Container images
        "mcr.microsoft.com",              # Microsoft Container Registry
        "*.data.mcr.microsoft.com",       # MCR data
        "management.azure.com",           # Azure management
        "login.microsoftonline.com",      # Azure AD
        "packages.microsoft.com",         # Microsoft packages
        "acs-mirror.azureedge.net",       # AKS mirror
        "dc.services.visualstudio.com",   # Telemetry
        "*.ods.opinsights.azure.com",     # Monitoring
        "*.oms.opinsights.azure.com",     # Monitoring
        "*.monitoring.azure.com",         # Monitoring
      ]
    }

    # Allow Ubuntu updates (for node OS)
    rule {
      name = "AllowUbuntuUpdates"
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16"]

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
      ]
    }

    # Allow Docker Hub (for pulling public images)
    rule {
      name = "AllowDockerHub"
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "*.docker.io",
        "*.docker.com",
        "production.cloudflare.docker.com",
      ]
    }

    # Allow GitHub (for Git operations)
    rule {
      name = "AllowGitHub"
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16"]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
      ]
    }
  }
}

# -----------------------------------------------------------------------------
# AZURE FIREWALL
# -----------------------------------------------------------------------------
# The actual firewall resource

resource "azurerm_firewall" "main" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main.id
  tags                = var.tags

  # Main IP configuration
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Management IP configuration (required for Basic SKU)
  management_ip_configuration {
    name                 = "fw-mgmt-ipconfig"
    subnet_id            = var.firewall_management_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall_management.id
  }
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS (for logging)
# -----------------------------------------------------------------------------
# Sends firewall logs to Log Analytics for monitoring
# Note: If enable_logs is true, log_analytics_workspace_id must be provided

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.enable_logs ? 1 : 0

  name                       = "diag-${var.firewall_name}"
  target_resource_id         = azurerm_firewall.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Enable all log categories
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  # Enable metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
