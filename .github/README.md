# GitHub Actions CI/CD Pipeline

Professional CI/CD pipeline for automated deployment and management of Azure hub-and-spoke infrastructure using Terraform.

## 📚 Documentation

- **[Azure OIDC Setup Guide](AZURE-OIDC-SETUP.md)** - Complete setup instructions for Azure OIDC authentication
- **[Pipeline Usage Guide](PIPELINE-USAGE.md)** - How to use the CI/CD workflows

## 🔄 Workflows

### Core Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **PR Plan** | `pr-plan.yml` | Pull requests | Validate and plan changes |
| **Deploy Dev** | `deploy-dev.yml` | Merge to develop | Auto-deploy to dev |
| **Deploy Prod** | `deploy-prod.yml` | Merge to main | Deploy to prod (with approval) |
| **Drift Detection** | `drift-detection.yml` | Weekly / Manual | Detect configuration drift |
| **Self-Service** | `self-service.yml` | Manual | Developer self-service operations |
| **Terraform Reusable** | `terraform-reusable.yml` | Called by others | Shared Terraform logic |

### Workflow Features

✅ **PR Plan**
- Automatic plan generation on PRs
- Cost estimation with Infracost
- TFLint validation
- Plan posted as PR comment

✅ **Deploy Dev**
- Automatic deployment (no approval)
- Issue creation on failure
- Quick iteration for development

✅ **Deploy Prod**
- Manual approval gate
- State backup before deployment
- Success/failure notifications
- Change documentation

✅ **Drift Detection**
- Weekly automated checks
- Detects manual Azure changes
- Creates issues with reports
- Prevents configuration drift

✅ **Self-Service**
- Safe developer operations
- Plan-only mode
- Cost checking
- Output viewing
- State refresh

## 🔐 Security

### Authentication
- **OIDC** - No secrets stored in GitHub
- **Federated Credentials** - Short-lived tokens
- **Granular Permissions** - Resource-level RBAC

### Secrets Required

| Secret | Description | Required For |
|--------|-------------|--------------|
| `AZURE_CLIENT_ID` | Azure AD Application ID | All workflows |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | All workflows |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | All workflows |
| `STATE_STORAGE_ACCOUNT` | Terraform state storage | State backup |
| `INFRACOST_API_KEY` | Infracost API key | Cost estimation |

See [AZURE-OIDC-SETUP.md](AZURE-OIDC-SETUP.md) for setup instructions.

### GitHub Environments

| Environment | Protection | Purpose |
|-------------|------------|---------|
| `dev` | None | Development deployments |
| `prod` | Requires approval | Production deployments |
| `prod-approval` | Required reviewers | Deployment approval gate |
| `prod-destroy-approval` | Multiple reviewers | Destroy operation approval |

## 🎯 Pipeline Flow

### Pull Request Flow
```
PR Created
  ↓
Detect Environment (dev/prod)
  ↓
Run Terraform Validation
  ↓
Generate Plan
  ↓
Run Infracost
  ↓
Post Comment on PR
```

### Development Deployment Flow
```
Merge to develop
  ↓
Generate Plan
  ↓
Auto-Apply (no approval)
  ↓
Notify on Success/Failure
```

### Production Deployment Flow
```
Merge to main
  ↓
Generate Plan
  ↓
⏸️  Wait for Approval
  ↓
Backup State
  ↓
Apply Changes
  ↓
Create Issue (success/failure)
```

## 📊 Pipeline Stages

Each deployment workflow runs through these stages:

1. **Validation**
   - `terraform fmt -check`
   - `terraform validate`
   - `tflint`

2. **Planning**
   - `terraform init`
   - `terraform plan`
   - Upload plan artifact

3. **Cost Estimation**
   - Infracost breakdown
   - Post estimate to PR (if applicable)

4. **Approval** (prod only)
   - Manual review required
   - Plan review
   - Cost review

5. **Backup** (prod only)
   - Download current state
   - Upload to backup container

6. **Apply**
   - `terraform apply`
   - Capture outputs

7. **Notification**
   - Create success issue (prod)
   - Create failure issue
   - Update step summary

## 🔧 Configuration Files

### TFLint Configuration
- **File**: `../.tflint.hcl`
- **Purpose**: Terraform linting rules
- **Features**:
  - Azure provider rules
  - Naming conventions
  - Best practice checks

### Workflow Variables

Workflows use these environment-specific paths:

```bash
# Backend configuration
environments/{environment}/backend.tf

# Variable files
environments/{environment}/terraform.tfvars

# State files
hub-spoke-{environment}.tfstate
```

## 📈 Monitoring

### Workflow Status
- View in **Actions** tab
- Filter by workflow name
- Check run history

### Success Metrics
- ✅ All checks pass
- ✅ Plan shows expected changes
- ✅ Costs within budget
- ✅ No drift detected

### Failure Handling
- ❌ Issue automatically created
- ❌ Logs available for review
- ❌ State backup available (prod)
- ❌ Team notified

## 🚀 Quick Start

### 1. Setup Azure OIDC
Follow [AZURE-OIDC-SETUP.md](AZURE-OIDC-SETUP.md) to configure Azure authentication.

### 2. Configure GitHub Secrets
Add required secrets in repository settings.

### 3. Create GitHub Environments
Set up environments with protection rules.

### 4. Test the Pipeline
```bash
# Create test PR
git checkout -b test/pipeline
echo "# Test" >> README.md
git commit -am "Test pipeline"
git push origin test/pipeline
# Create PR: test/pipeline → develop
```

### 5. Deploy to Dev
Merge PR to develop - deployment starts automatically.

### 6. Deploy to Prod
Create PR: develop → main, get approval, merge.

## 🔍 Troubleshooting

### Common Issues

**OIDC Authentication Fails**
- Check Azure federated credentials
- Verify secrets are correct
- Ensure service principal has permissions

**Terraform Init Fails**
- Check backend configuration
- Verify storage account access
- Check state file permissions

**Plan Shows Unexpected Changes**
- Run drift detection
- Check for manual changes
- Review recent deployments

**Approval Not Working**
- Verify environment exists
- Check reviewers are set
- Ensure user has access

See [PIPELINE-USAGE.md](PIPELINE-USAGE.md) for detailed troubleshooting.

## 📝 Best Practices

1. **Always Use PRs** - Never push directly to main/develop
2. **Review Plans** - Check what will change before approving
3. **Monitor Costs** - Review Infracost reports
4. **Check Drift** - Respond to drift detection issues
5. **Test in Dev** - Always test changes in dev first
6. **Document Changes** - Add meaningful commit messages

## 🔄 Workflow Customization

### Adding New Environments

1. Create new environment in GitHub Settings
2. Add federated credential in Azure
3. Create new environment folder: `environments/staging/`
4. Copy workflow file and update environment name

### Adding Notifications

Uncomment Slack/Teams notification steps in workflows:

```yaml
# Example Slack notification (add to workflow)
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Deployment ${{ job.status }}"
      }
```

### Customizing Approval

Edit `deploy-prod.yml` approval settings:

```yaml
environment:
  name: prod-approval
  url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

## 🆘 Support

- **Documentation**: Check guides in `.github/` directory
- **Issues**: Create GitHub issue with `pipeline` label
- **Logs**: Review workflow run logs for errors
- **Team**: Ask in #infrastructure channel

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [Azure Login Action](https://github.com/Azure/login)
- [Infracost GitHub Action](https://github.com/infracost/actions)

---

**CI/CD Pipeline Version**: 1.0.0
**Last Updated**: 2024-12-03
**Maintained by**: Platform Team
