# Azure Hub-and-Spoke Network Architecture with Terraform

> 🎯 **Easy-to-understand Azure infrastructure** - Built so even a 14-year-old IT enthusiast can deploy it!

This project creates a production-ready Azure hub-and-spoke network architecture with AKS clusters, shared services, and Azure Firewall - all using Terraform.

## 📋 Table of Contents

- [What Does This Do?](#what-does-this-do)
- [Architecture Overview](#architecture-overview)
- [What Gets Created](#what-gets-created)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Backend Configuration](BACKEND-SETUP.md) 📄
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)
- [Security Best Practices](#security-best-practices)

## 🤔 What Does This Do?

This Terraform code creates a complete Azure cloud environment with:

- **4 Virtual Networks** (like different buildings in a campus)
  - 1 Hub network (the main building)
  - 3 Spoke networks (Dev, Prod, and Shared services)
- **Azure Firewall** (the security checkpoint for all traffic)
- **2 Kubernetes Clusters** (one for development, one for production)
- **Container Registry** (ACR) - to store your Docker images
- **Key Vault** - to store your secrets securely
- **Private Endpoints** - so services talk privately (not over internet)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    HUB VNET (10.0.0.0/16)                   │ │
│  │                                                             │ │
│  │  ┌──────────────────┐          ┌──────────────────┐       │ │
│  │  │ Azure Firewall   │          │  VPN Gateway     │       │ │
│  │  │  (Basic/Std)     │          │   (Future)       │       │ │
│  │  └────────┬─────────┘          └──────────────────┘       │ │
│  │           │                                                │ │
│  └───────────┼────────────────────────────────────────────────┘ │
│              │                                                   │
│      ┌───────┼───────────┬──────────────┬──────────────┐       │
│      │       │           │              │              │       │
│  ┌───▼───────▼─┐    ┌────▼──────┐  ┌───▼──────────┐  │       │
│  │ Dev Spoke   │    │Prod Spoke │  │Shared Spoke  │  │       │
│  │10.1.0.0/16  │    │10.2.0.0/16│  │10.3.0.0/16   │  │       │
│  │             │    │           │  │              │  │       │
│  │ ┌─────────┐ │    │┌─────────┐│  │ ┌──────────┐ │  │       │
│  │ │   AKS   │ │    ││   AKS   ││  │ │   ACR    │ │  │       │
│  │ │  (Dev)  │ │    ││  (Prod) ││  │ │ KeyVault │ │  │       │
│  │ │ Private │ │    ││ Private ││  │ │ Private  │ │  │       │
│  │ └─────────┘ │    │└─────────┘│  │ └──────────┘ │  │       │
│  └─────────────┘    └───────────┘  └──────────────┘  │       │
│                                                        │       │
└────────────────────────────────────────────────────────────────┘

All traffic between spokes goes through the Azure Firewall
Private endpoints ensure services never touch the public internet
```

## 📦 What Gets Created

### Resource Groups
- `rg-hubspoke-{env}-uks-hub` - Hub resources
- `rg-hubspoke-{env}-uks-dev` - Dev AKS cluster
- `rg-hubspoke-{env}-uks-prod` - Prod AKS cluster
- `rg-hubspoke-{env}-uks-shared` - Shared services (ACR, Key Vault)

### Networking
- 4 Virtual Networks with proper CIDR blocks
- VNet peering (hub-to-spoke topology)
- Network Security Groups (NSGs)
- Route tables directing traffic through firewall

### Security
- Azure Firewall with application and network rules
- Managed identities for AKS clusters
- RBAC role assignments
- Private endpoints for ACR and Key Vault
- Private DNS zones

### Compute
- 2 AKS clusters (Dev and Prod)
- Private cluster configuration
- Auto-scaling enabled
- Azure CNI networking
- Azure Policy add-on

### Shared Services
- Azure Container Registry (Premium/Standard)
- Azure Key Vault with RBAC
- Private endpoints
- ACR pull permissions for AKS

### Monitoring
- Log Analytics workspace
- Diagnostic settings for all resources
- Azure Monitor integration

## ✅ Prerequisites

Before you start, make sure you have:

1. **Azure Subscription** - You need an active Azure account
   - [Create a free account](https://azure.microsoft.com/free/)

2. **Azure CLI** - To interact with Azure
   ```bash
   # Install on macOS
   brew install azure-cli

   # Install on Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Install on Windows
   # Download from: https://aka.ms/installazurecliwindows
   ```

3. **Terraform** - Version 1.6 or higher
   ```bash
   # Install on macOS
   brew install terraform

   # Install on Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

4. **kubectl** - To interact with Kubernetes (optional but recommended)
   ```bash
   # Install on macOS
   brew install kubectl

   # Install on Ubuntu/Debian
   sudo snap install kubectl --classic
   ```

## 🚀 Quick Start

### 1. Clone and Prepare

```bash
# Clone the repository
git clone <your-repo-url>
cd new-hub-and-spokes

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

### 2. Configure Backend (Recommended)

Each environment has its own backend configuration:

```bash
# For dev environment
cp environments/backend-dev.tf backend.tf

# OR for prod environment
cp environments/backend-prod.tf backend.tf

# Then edit backend.tf and update the storage_account_name
vim backend.tf
```

Create the storage account first:
```bash
./scripts/create-backend.sh
```

### 3. Deploy Development Environment

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan -var-file="environments/dev.tfvars"

# Create the infrastructure
terraform apply -var-file="environments/dev.tfvars"
```

### 4. Deploy Production Environment

```bash
# Review production plan
terraform plan -var-file="environments/prod.tfvars"

# Create production infrastructure
terraform apply -var-file="environments/prod.tfvars"
```

### 5. Connect to Your AKS Cluster

```bash
# Get credentials for dev cluster
az aks get-credentials --resource-group rg-hubspoke-dev-uks-dev --name aks-hubspoke-dev-uks-dev

# Test connection
kubectl get nodes

# Get credentials for prod cluster
az aks get-credentials --resource-group rg-hubspoke-prod-uks-prod --name aks-hubspoke-prod-uks-prod
```

## 📁 Project Structure

```
.
├── main.tf                    # Main configuration (calls all modules)
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Terraform and provider versions
├── locals.tf                  # Local computed values
├── terraform.tfvars.example   # Example variable values
│
├── modules/                   # Reusable modules
│   ├── networking/           # VNets, subnets, peering, NSGs
│   ├── firewall/             # Azure Firewall and policies
│   ├── aks/                  # AKS cluster configuration
│   ├── shared-services/      # ACR, Key Vault, private endpoints
│   └── security/             # Managed identities, RBAC
│
├── environments/              # Environment-specific configs
│   ├── dev.tfvars            # Development settings
│   ├── prod.tfvars           # Production settings
│   ├── backend-dev.tf        # Dev backend configuration
│   └── backend-prod.tf       # Prod backend configuration
│
├── scripts/                   # Helper scripts
│   ├── deploy.sh             # Deployment script
│   └── destroy.sh            # Cleanup script
│
├── Makefile                   # Common commands
└── README.md                  # This file
```

## ⚙️ Configuration

### Environment Variables

You can customize the deployment by editing `environments/dev.tfvars` or `environments/prod.tfvars`.

Key settings:

```hcl
# Environment and location
environment  = "dev"
location     = "uksouth"

# AKS cluster sizing
dev_aks_node_count = 2
dev_aks_node_size  = "Standard_D2s_v3"

# Firewall SKU
firewall_sku_tier = "Basic"  # or "Standard" for prod

# Shared services
acr_sku       = "Standard"   # or "Premium" for geo-replication
key_vault_sku = "standard"   # or "premium" for HSM
```

### Naming Convention

All resources follow Azure Cloud Adoption Framework naming:

- Resource Groups: `rg-{project}-{env}-{region}-{type}`
- VNets: `vnet-{project}-{env}-{region}-{type}`
- Subnets: `snet-{project}-{env}-{region}-{purpose}`
- AKS: `aks-{project}-{env}-{region}-{type}`

## 🐛 Troubleshooting

### Common Issues

**1. Terraform Init Fails**
```bash
# Clear cache and re-initialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**2. Authentication Errors**
```bash
# Re-login to Azure
az login
az account show
```

**3. Quota Limits**
```bash
# Check your quota
az vm list-usage --location uksouth --output table
```

**4. AKS Private Cluster Access**
- Private AKS clusters can only be accessed from within the VNet
- Use Azure Bastion or VPN to access the cluster
- Or use `az aks command invoke` for commands

**5. Firewall Rules**
- If pods can't reach internet, check firewall rules
- Review logs: Azure Portal → Firewall → Logs

## 💰 Cost Estimation

Approximate monthly costs for UK South region:

### Development Environment
- Hub VNet with Firewall (Basic): ~£120/month
- Dev AKS (2 nodes, D2s_v3): ~£100/month
- ACR Standard: ~£4/month
- Key Vault: ~£1/month
- **Total: ~£225/month**

### Production Environment
- Hub VNet with Firewall (Standard): ~£700/month
- Prod AKS (3 nodes, D4s_v3): ~£300/month
- ACR Premium: ~£34/month
- Key Vault Premium: ~£1/month
- **Total: ~£1,035/month**

💡 **Tip**: Use `terraform destroy` when not in use to save costs!

## 🔒 Security Best Practices

✅ **What This Project Does**
- Uses private endpoints for PaaS services
- Implements network segmentation
- Uses managed identities (no passwords!)
- Enforces traffic through firewall
- Enables Azure Policy
- Uses RBAC for access control

⚠️ **Additional Recommendations**
1. Enable Azure Defender for Cloud
2. Implement Azure DDoS Protection (Standard tier)
3. Set up Azure Backup for persistent volumes
4. Configure Azure Monitor alerts
5. Implement pod security policies
6. Use Azure Key Vault for all secrets
7. Enable audit logging
8. Implement network policies in AKS

## 📚 Additional Resources

- [Azure Hub-Spoke Topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

## 🤝 Contributing

Found an issue or want to improve this? Feel free to submit a pull request!

## 📄 License

This project is provided as-is for educational and production use.

---

**Made with ❤️ by a DevOps Engineer who believes infrastructure should be simple!**
