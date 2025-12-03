# GitHub Actions CI/CD Pipeline - Usage Guide

This guide explains how to use the GitHub Actions CI/CD pipeline for deploying and managing Azure infrastructure.

## 📋 Table of Contents

- [Overview](#overview)
- [Workflows](#workflows)
- [Common Scenarios](#common-scenarios)
- [Approval Process](#approval-process)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The CI/CD pipeline automates the deployment and management of Azure hub-and-spoke infrastructure using Terraform. It includes:

- ✅ Automated plan generation on pull requests
- ✅ Automatic deployment to dev environment
- ✅ Manual approval gates for production
- ✅ Cost estimation with Infracost
- ✅ Weekly drift detection
- ✅ Self-service operations for developers

---

## 📊 Workflows

### 1. Pull Request Workflow (`pr-plan.yml`)

**Triggered by**: Pull requests to `develop` or `main` branches

**Purpose**: Validate Terraform changes and show plan

**Actions**:
- Detects target environment based on base branch
- Runs `terraform fmt`, `validate`, and `tflint`
- Generates Terraform plan
- Posts cost estimate (Infracost)
- Comments plan output on PR

**Example**:
```bash
# Create a PR from feature branch to develop
git checkout -b feature/add-bastion
# Make your changes
git add .
git commit -m "Add Azure Bastion to hub"
git push origin feature/add-bastion
# Create PR on GitHub: feature/add-bastion → develop
```

The workflow will automatically run and comment on your PR with the plan.

---

### 2. Development Deployment (`deploy-dev.yml`)

**Triggered by**:
- Merge to `develop` branch (automatic)
- Manual workflow dispatch

**Purpose**: Deploy changes to dev environment

**Actions**:
- Runs Terraform plan
- Automatically applies changes (no approval needed)
- Creates issue if deployment fails
- Provides AKS connection commands

**Example - Automatic**:
```bash
# Changes are automatically deployed when PR is merged to develop
git checkout develop
git merge feature/add-bastion
git push origin develop
# ✅ Deployment starts automatically
```

**Example - Manual**:
1. Go to **Actions** tab
2. Select **Deploy to Development**
3. Click **Run workflow**
4. Choose action: `apply`, `plan`, or `destroy`
5. Click **Run workflow**

---

### 3. Production Deployment (`deploy-prod.yml`)

**Triggered by**:
- Merge to `main` branch
- Manual workflow dispatch

**Purpose**: Deploy changes to production (with approval)

**Actions**:
- Runs Terraform plan
- **Waits for manual approval** (prod-approval environment)
- Backs up Terraform state before apply
- Applies changes to production
- Creates success/failure notification issue

**Approval Flow**:
```
PR merged to main
  ↓
Plan generated
  ↓
⏸️  APPROVAL REQUIRED
  ↓
Reviewer approves in GitHub
  ↓
State backup created
  ↓
Apply to production
  ↓
Success notification
```

**Example**:
```bash
# Merge develop to main (usually via PR)
git checkout main
git merge develop
git push origin main

# Workflow starts automatically
# 1. Plan is generated
# 2. Notification sent to approvers
# 3. Approver reviews plan and approves
# 4. Deployment continues
```

---

### 4. Drift Detection (`drift-detection.yml`)

**Triggered by**:
- Weekly schedule (Monday 8:00 AM UTC)
- Manual workflow dispatch

**Purpose**: Detect infrastructure drift

**Actions**:
- Runs `terraform plan` without applying
- Checks if infrastructure matches configuration
- Creates issue if drift detected
- Uploads drift report as artifact

**What is Drift?**

Drift occurs when someone makes manual changes in Azure Portal that aren't reflected in Terraform. Example:
- Someone adds a subnet via Azure Portal
- Someone changes a VM size manually
- A resource is deleted outside of Terraform

**Example - Manual Run**:
1. Go to **Actions** tab
2. Select **Drift Detection**
3. Click **Run workflow**
4. Choose environment: `dev`, `prod`, or `both`
5. Click **Run workflow**

**If Drift Detected**:
- Issue is automatically created with details
- Download drift report from workflow artifacts
- Review changes
- Fix by either:
  - Importing changes into Terraform
  - Re-applying Terraform to revert changes

---

### 5. Self-Service Operations (`self-service.yml`)

**Triggered by**: Manual workflow dispatch only

**Purpose**: Allow developers to perform safe operations

**Available Operations**:

#### Plan Only
Shows what would change without making changes
```
1. Go to Actions → Self-Service Operations
2. Choose environment: dev or prod
3. Choose operation: plan-only
4. Add optional message
5. Run workflow
6. Review plan in workflow logs
```

#### Validate Config
Checks Terraform configuration for errors
```
1. Go to Actions → Self-Service Operations
2. Choose operation: validate-config
3. Run workflow
4. See validation results in summary
```

#### Show Outputs
Displays Terraform outputs (connection strings, IPs, etc.)
```
1. Go to Actions → Self-Service Operations
2. Choose environment
3. Choose operation: show-outputs
4. Run workflow
5. Download outputs artifact or view in summary
```

#### Check Costs
Generates cost estimate for current configuration
```
1. Go to Actions → Self-Service Operations
2. Choose environment
3. Choose operation: check-costs
4. Run workflow
5. Review cost report in summary
```

#### Refresh State
Updates state file to match real infrastructure (no changes)
```
1. Go to Actions → Self-Service Operations
2. Choose environment
3. Choose operation: refresh-state
4. Run workflow
```

---

## 🎭 Common Scenarios

### Scenario 1: Deploy New Feature to Dev

```bash
1. Create feature branch
   git checkout -b feature/my-feature

2. Make your changes
   vim main.tf

3. Commit and push
   git add .
   git commit -m "Add my feature"
   git push origin feature/my-feature

4. Create PR: feature/my-feature → develop
   - Workflow runs automatically
   - Review plan in PR comments
   - Review cost estimate

5. Get PR approved and merge
   - Deployment to dev starts automatically
   - Monitor in Actions tab

6. Verify deployment
   - Check workflow outputs for connection commands
   - Test in dev environment
```

### Scenario 2: Promote Dev to Production

```bash
1. Create PR: develop → main
   - Production plan is generated
   - Review changes carefully

2. Get PR approved by team
   - At least 2 approvers recommended

3. Merge PR to main
   - Prod workflow starts
   - Plan is generated

4. Approve deployment
   - Designated approver reviews plan
   - Approves in GitHub Environments

5. Monitor deployment
   - Watch workflow progress
   - Verify success notification

6. Verify production
   - Connect to prod AKS
   - Verify services are running
```

### Scenario 3: Emergency Rollback

```bash
1. Identify last known good commit
   git log --oneline

2. Create revert PR
   git revert <commit-sha>
   git push origin main

3. Expedite approval
   - Use production approval process
   - Document reason for rollback

4. Monitor rollback
   - Ensure clean revert
   - Verify state backup exists

5. Post-mortem
   - Document what went wrong
   - Update runbooks
```

### Scenario 4: Investigate Drift

```bash
1. Drift issue created automatically (weekly)
   - Check issue for affected resources

2. Download drift report
   - Go to workflow run
   - Download "drift-report-env" artifact

3. Review changes
   cat drift-report.txt
   # Look for unexpected changes

4. Determine cause
   - Check Azure Activity Log
   - Check who made manual changes

5. Fix drift
   Option A: Import changes
   terraform import azurerm_xxx.xxx /subscriptions/.../

   Option B: Revert changes
   terraform apply  # Re-apply to revert

   Option C: Update config
   # Update .tf files to match desired state
```

---

## ✅ Approval Process

### Dev Environment
- **Approval Required**: ❌ No
- **Auto-deploy**: ✅ Yes
- **Use Case**: Fast iteration, testing

### Prod Environment
- **Approval Required**: ✅ Yes
- **Approvers**: Platform team leads
- **Approval Environment**: `prod-approval`
- **Use Case**: Controlled production changes

### How to Approve

1. **Notification**
   - Approvers receive GitHub notification
   - Email notification (if configured)

2. **Review**
   - Click notification link
   - Review workflow run
   - Check Terraform plan output
   - Review Infracost report

3. **Approve or Reject**
   - Go to workflow run page
   - Click **Review deployments**
   - Select environment: `prod-approval`
   - Add comment (optional)
   - Click **Approve deployment** or **Reject deployment**

4. **Monitor**
   - If approved: deployment continues
   - If rejected: deployment stops
   - Both create notifications

---

## 📊 Monitoring

### Workflow Status

Check workflow status:
1. Go to **Actions** tab
2. View recent workflow runs
3. Click on run for details

### Success Indicators
- ✅ All jobs green
- ✅ No error messages
- ✅ Success issue created
- ✅ Terraform outputs displayed

### Failure Indicators
- ❌ Job failed (red X)
- ❌ Error in logs
- ❌ Failure issue created
- ❌ State backup created (prod)

### Notifications

**Automatic Notifications**:
- Issues created for failures
- Issues created for drift detection
- Issues created for successful prod deployments

**Customize Notifications** (Future):
- Add Slack integration
- Add Teams integration
- Add email notifications

---

## 🔧 Troubleshooting

### Issue: Workflow Fails at Login

**Cause**: OIDC configuration issue

**Solution**:
1. Verify secrets are configured correctly
2. Check federated credentials in Azure AD
3. Ensure service principal has correct permissions
4. See [AZURE-OIDC-SETUP.md](AZURE-OIDC-SETUP.md)

### Issue: Terraform Init Fails

**Cause**: Backend configuration or state access issue

**Solution**:
```bash
# Check storage account exists
az storage account show --name <storage-account>

# Check service principal has access
az role assignment list --assignee <app-id>

# Verify backend configuration
cat environments/dev/backend.tf
```

### Issue: Terraform Plan Shows Unexpected Changes

**Cause**: Drift or configuration mismatch

**Solution**:
1. Run drift detection workflow
2. Review what changed manually
3. Update Terraform config or revert manual changes
4. Re-run plan

### Issue: Approval Not Working

**Cause**: Environment not configured or approvers not set

**Solution**:
1. Go to Settings → Environments
2. Check `prod-approval` environment exists
3. Verify required reviewers are set
4. Check user has repository access

### Issue: Cost Estimate Not Showing

**Cause**: Infracost API key missing or invalid

**Solution**:
1. Get API key from infracost.io
2. Add to GitHub secrets: `INFRACOST_API_KEY`
3. Re-run workflow

---

## 📝 Best Practices

1. **Always Create PRs**
   - Never push directly to `develop` or `main`
   - Let workflows validate your changes

2. **Review Plans Carefully**
   - Check what resources will be created/changed/destroyed
   - Verify costs are acceptable
   - Look for unexpected changes

3. **Use Self-Service for Investigation**
   - Run `plan-only` to see what would change
   - Use `check-costs` before major changes
   - Use `validate-config` after editing files

4. **Monitor Drift**
   - Review drift detection issues promptly
   - Don't make manual changes in Azure Portal
   - Use Terraform for all infrastructure changes

5. **Production Deployments**
   - Test in dev first
   - Get peer review on PRs
   - Schedule prod deployments during maintenance windows
   - Have rollback plan ready

6. **Emergency Changes**
   - Use `workflow_dispatch` for urgent changes
   - Document reason in workflow message
   - Still require approval for prod

---

## 📚 Quick Reference

| Task | Workflow | Trigger |
|------|----------|---------|
| Validate changes | PR Plan | Create PR |
| Deploy to dev | Deploy Dev | Merge to develop |
| Deploy to prod | Deploy Prod | Merge to main + approve |
| Check for drift | Drift Detection | Monday 8 AM or manual |
| View outputs | Self-Service | Manual |
| Check costs | Self-Service | Manual |
| Test config | Self-Service | Manual |

---

## 🆘 Getting Help

1. **Check workflow logs** - Most errors are explained in logs
2. **Review documentation** - Check AZURE-OIDC-SETUP.md
3. **Check GitHub Issues** - Look for similar problems
4. **Ask the team** - Post in #infrastructure channel
5. **Create issue** - Document the problem for team review

---

**Happy Deploying!** 🚀
