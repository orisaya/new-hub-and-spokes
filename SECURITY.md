# Security Best Practices

This document outlines security best practices and compliance recommendations for the Azure hub-and-spoke architecture.

## 🔒 Built-in Security Features

This infrastructure includes the following security features out of the box:

### Network Security
- ✅ **Hub-and-Spoke Topology** - Centralized traffic control
- ✅ **Azure Firewall** - All egress traffic filtered through firewall
- ✅ **Network Security Groups (NSGs)** - Subnet-level security
- ✅ **Private Endpoints** - PaaS services accessible only via private IPs
- ✅ **Private AKS Clusters** - API server not exposed to internet
- ✅ **VNet Peering** - Secure internal network communication

### Identity & Access Management
- ✅ **Managed Identities** - No hardcoded credentials
- ✅ **Azure RBAC** - Role-based access control
- ✅ **Key Vault RBAC** - Secure secret management
- ✅ **ACR Integration** - Secure image pull via managed identity

### Monitoring & Compliance
- ✅ **Azure Policy** - Automated compliance enforcement
- ✅ **Log Analytics** - Centralized logging
- ✅ **Diagnostic Settings** - Audit logs for all resources

## 🛡️ Recommended Additional Security Measures

### 1. Enable Azure Defender (Microsoft Defender for Cloud)

```bash
# Enable Defender for Container Registries
az security pricing create \
  --name ContainerRegistry \
  --tier Standard

# Enable Defender for Kubernetes
az security pricing create \
  --name KubernetesService \
  --tier Standard

# Enable Defender for Key Vault
az security pricing create \
  --name KeyVaults \
  --tier Standard

# Enable Defender for Resource Manager
az security pricing create \
  --name Arm \
  --tier Standard
```

**Cost**: ~£12/month per resource type
**Benefit**: Advanced threat protection and security alerts

### 2. Implement Azure DDoS Protection

```bash
# Create DDoS protection plan
az network ddos-protection create \
  --resource-group rg-hubspoke-prod-uks-hub \
  --name ddos-protection-prod \
  --location uksouth
```

**Cost**: ~£2,240/month (Standard tier)
**Benefit**: Protection against DDoS attacks (recommended for production)

### 3. Configure Network Policies in AKS

Add this to your Kubernetes manifests:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**Cost**: Free
**Benefit**: Pod-level network isolation

### 4. Enable Pod Security Standards

Apply pod security policies:

```bash
kubectl label namespace default \
  pod-security.kubernetes.io/enforce=restricted
```

**Cost**: Free
**Benefit**: Enforces secure pod configurations

### 5. Implement Image Scanning

```bash
# Enable vulnerability scanning in ACR
az acr update \
  --name acrhubspokedevuks \
  --resource-group rg-hubspoke-dev-uks-shared

# Enable Microsoft Defender for container scanning
az security assessment create \
  --name "containerRegistryVulnerabilityAssessment" \
  --status "Healthy"
```

**Cost**: Included with Defender for Cloud
**Benefit**: Automatic scanning of container images for vulnerabilities

### 6. Configure Azure Backup

```bash
# Create recovery services vault
az backup vault create \
  --resource-group rg-hubspoke-prod-uks-hub \
  --name rsv-hubspoke-prod \
  --location uksouth
```

**Cost**: Pay per GB (varies)
**Benefit**: Backup for persistent volumes and configurations

## 🔐 Secret Management Best Practices

### 1. Never Commit Secrets to Git

- ✅ Use Azure Key Vault for all secrets
- ✅ Use managed identities to access Key Vault
- ✅ Enable Key Vault audit logging
- ❌ Never hardcode passwords or API keys

### 2. Rotate Secrets Regularly

```bash
# Example: Rotate storage account key
az storage account keys renew \
  --resource-group <rg-name> \
  --account-name <storage-account> \
  --key primary
```

### 3. Use Azure Key Vault CSI Driver in AKS

Deploy the CSI driver:

```bash
# Enable CSI driver add-on
az aks enable-addons \
  --resource-group rg-hubspoke-dev-uks-dev \
  --name aks-hubspoke-dev-uks-dev \
  --addons azure-keyvault-secrets-provider
```

Then use secrets in pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      volumeAttributes:
        secretProviderClass: "azure-kvname"
```

## 📊 Compliance Recommendations

### ISO 27001 / SOC 2 Compliance

If you need compliance with ISO 27001 or SOC 2:

1. **Enable Azure Policy** (already included)
2. **Configure audit logging** (already included)
3. **Implement data encryption at rest** (already enabled)
4. **Enable TLS 1.2 minimum** (already configured)
5. **Regular vulnerability assessments** (enable Defender)
6. **Document incident response procedures**

### GDPR Compliance

For GDPR compliance:

1. **Data residency**: Resources in UK South region
2. **Encryption**: All data encrypted at rest and in transit
3. **Access controls**: RBAC implemented
4. **Audit logs**: Enabled via Log Analytics
5. **Data retention**: Configure retention policies

```bash
# Set retention policy
az monitor log-analytics workspace update \
  --resource-group rg-hubspoke-dev-uks-hub \
  --workspace-name log-hubspoke-dev-uks \
  --retention-time 90
```

### PCI DSS Compliance

For payment card data:

1. **Network segmentation**: Create separate subnets for PCI workloads
2. **Firewall rules**: Restrict access to PCI resources
3. **Encryption**: TLS 1.2+ for all communications
4. **Logging**: Extended retention (12 months)
5. **Quarterly scans**: Use Azure Security Center

## 🚨 Monitoring and Alerting

### Set Up Security Alerts

```bash
# Create action group for alerts
az monitor action-group create \
  --name security-alerts \
  --resource-group rg-hubspoke-prod-uks-hub \
  --short-name SecAlerts \
  --email security-team security@example.com

# Create alert for firewall rule hits
az monitor metrics alert create \
  --name firewall-high-traffic \
  --resource-group rg-hubspoke-prod-uks-hub \
  --scopes /subscriptions/<sub-id>/resourceGroups/rg-hubspoke-prod-uks-hub/providers/Microsoft.Network/azureFirewalls/afw-hubspoke-prod-uks \
  --condition "total firewallrulehits > 10000" \
  --description "Alert when firewall rule hits exceed threshold" \
  --action security-alerts
```

### Security Monitoring Checklist

Monitor these metrics:

- [ ] Failed authentication attempts
- [ ] Firewall rule denials
- [ ] Unusual network traffic patterns
- [ ] Container image vulnerabilities
- [ ] Key Vault access patterns
- [ ] AKS API server requests
- [ ] Resource configuration changes

## 🔍 Security Audit Checklist

Perform regular security audits:

### Monthly
- [ ] Review firewall logs for unusual patterns
- [ ] Check for container vulnerabilities
- [ ] Review RBAC assignments
- [ ] Check for unused resources
- [ ] Verify backup configurations

### Quarterly
- [ ] Full security assessment with Azure Security Center
- [ ] Review and update firewall rules
- [ ] Penetration testing (if required)
- [ ] Compliance report generation
- [ ] Update runbooks and procedures

### Annually
- [ ] Review disaster recovery plan
- [ ] Update security policies
- [ ] Comprehensive audit
- [ ] Staff security training
- [ ] Review compliance certifications

## 📚 Security Resources

- [Azure Security Baseline for AKS](https://docs.microsoft.com/azure/aks/security-baseline)
- [Azure Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)
- [Azure Key Vault Security](https://docs.microsoft.com/azure/key-vault/general/security-features)
- [Azure Firewall Documentation](https://docs.microsoft.com/azure/firewall/)
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure)

## 🚀 Quick Security Wins

Easy improvements with big impact:

1. **Enable MFA** for all Azure accounts
2. **Review NSG rules** monthly
3. **Enable diagnostic logs** for all resources
4. **Use Azure Bastion** instead of direct SSH
5. **Implement pod security policies**
6. **Scan container images** before deployment
7. **Use private endpoints** for all PaaS services (already implemented)
8. **Regular patching** of AKS nodes (automatic with maintenance windows)

## 🆘 Security Incident Response

If you detect a security incident:

1. **Isolate affected resources** - Use NSGs to block traffic
2. **Collect evidence** - Review logs in Log Analytics
3. **Notify stakeholders** - Use your action groups
4. **Remediate** - Apply fixes and test
5. **Document** - Record incident and lessons learned
6. **Review** - Update procedures to prevent recurrence

---

**Remember**: Security is not a one-time task, it's an ongoing process!
