# ============================================================================
# TFLint Configuration
# ============================================================================
# This file configures TFLint for Terraform code quality checks
# TFLint helps catch errors and enforce best practices

config {
  # Enable module inspection
  module = true

  # Force required version
  force = false
}

# ============================================================================
# Enable Azure Provider Plugin
# ============================================================================
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# ============================================================================
# Terraform Rules
# ============================================================================

# Require terraform version constraint
rule "terraform_required_version" {
  enabled = true
}

# Require provider version constraints
rule "terraform_required_providers" {
  enabled = true
}

# Disallow deprecated syntax
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow interpolation-only expressions
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Ensure variables have descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Ensure outputs have descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Variable naming
  variable {
    format = "snake_case"
  }

  # Output naming
  output {
    format = "snake_case"
  }

  # Local naming
  locals {
    format = "snake_case"
  }

  # Module naming
  module {
    format = "snake_case"
  }
}

# Ensure standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Disallow variables without types
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Ensure workspace usage
rule "terraform_workspace_remote" {
  enabled = false  # We use Azure Storage backend
}

# ============================================================================
# Azure-Specific Rules
# ============================================================================

# Ensure resource group location matches
rule "azurerm_resource_group_location" {
  enabled = true
}

# Ensure storage account naming
rule "azurerm_storage_account_name" {
  enabled = true
}

# Ensure key vault naming
rule "azurerm_key_vault_name" {
  enabled = true
}

# Ensure AKS configuration best practices
rule "azurerm_kubernetes_cluster_node_pool_name" {
  enabled = true
}
