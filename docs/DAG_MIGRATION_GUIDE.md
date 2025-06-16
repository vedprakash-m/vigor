# Migration to DAG-Based CI/CD Pipeline

## 🎯 **Why This Change?**

Your original question highlighted a critical issue: "Why are the CI/CD tasks running disparately instead of a DAG style workflow?"

The old setup had:

- **backend-ci.yml** - Independent backend checks
- **frontend-ci.yml** - Independent frontend checks
- **e2e-tests.yml** - Separate E2E tests
- **deploy.yml** - Standalone deployment

**Problems:**
❌ No orchestration between workflows
❌ Deployment could happen even if tests failed
❌ No staging validation
❌ Parallel execution where sequential was needed
❌ No proper failure handling

## 🔄 **New DAG Architecture**

The new `ci-cd-pipeline.yml` implements a proper Directed Acyclic Graph:

```
┌─────────────────┐
│ Detect Changes  │
└─────────┬───────┘
          │
    ┌─────▼─────┐
    │  Stage 1  │ ◄── Quality Checks (Parallel)
    │ Backend   │
    │ Frontend  │
    │ Infra     │
    └─────┬─────┘
          │
    ┌─────▼─────┐
    │  Stage 2  │ ◄── Integration Tests
    │ E2E Tests │
    └─────┬─────┘
          │
    ┌─────▼─────┐
    │  Stage 3  │ ◄── Staging Deployment
    │ Deploy +  │
    │ Verify    │
    └─────┬─────┘
          │
    ┌─────▼─────┐
    │  Stage 4  │ ◄── Production Deployment
    │ Deploy +  │
    │ Verify    │
    └───────────┘
```

## 📋 **Migration Steps**

### **Phase 1: Backup & Test** (Immediate)

1. **Create backup folder**:

   ```bash
   mkdir -p .github/workflows/legacy
   mv .github/workflows/backend-ci.yml .github/workflows/legacy/
   mv .github/workflows/frontend-ci.yml .github/workflows/legacy/
   mv .github/workflows/e2e-tests.yml .github/workflows/legacy/
   # Keep deploy.yml for now as fallback
   ```

2. **Test new pipeline** on a feature branch first

### **Phase 2: Environment Setup** (Next)

1. **Create GitHub Environments**:

   - Go to Repository Settings → Environments
   - Create "staging" environment
   - Create "production" environment with protection rules

2. **Configure App Service Slots**:
   ```bash
   az webapp deployment slot create \
     --name vigor-backend \
     --resource-group vigor-rg \
     --slot staging
   ```

### **Phase 3: Secrets & Dependencies** (Required)

Ensure these secrets exist in GitHub:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `DATABASE_URL`
- `SECRET_KEY`
- `OPENAI_API_KEY`
- `LLM_PROVIDER`
- `AZURE_KEY_VAULT_URL`

### **Phase 4: Validation** (Critical)

1. **Test the workflow** with a small change
2. **Monitor first full run** end-to-end
3. **Verify staging deployment** works
4. **Confirm production promotion** functions

### **Phase 5: Cleanup** (Final)

Once validated, remove legacy files:

```bash
rm -rf .github/workflows/legacy
rm .github/workflows/deploy.yml  # Replaced by new pipeline
```

## 🔍 **Key Benefits**

### **Safety** 🛡️

- **No deployment without passing tests**
- **Staging validation before production**
- **Automatic rollback on failure**

### **Efficiency** ⚡

- **Smart change detection** (only test what changed)
- **Parallel quality checks** (backend + frontend simultaneously)
- **Optimized resource usage**

### **Visibility** 👁️

- **Clear pipeline visualization**
- **Easy failure diagnosis**
- **Performance monitoring**

## 🚨 **Potential Issues & Solutions**

### **Issue: Long Pipeline Runtime**

**Solution**: Change detection optimizes by skipping unchanged components

### **Issue: Staging Environment Costs**

**Solution**: Use deployment slots (included in App Service plan)

### **Issue: Failed Staging Deployment**

**Solution**: Pipeline stops, doesn't affect production

### **Issue: Secrets Not Found**

**Solution**: Verify all required secrets are configured in GitHub

## 📊 **Monitoring & Metrics**

The new pipeline provides:

- **Pipeline duration** tracking
- **Stage success rates**
- **Performance baselines**
- **Automatic issue creation** on failures

## 🔧 **Rollback Plan**

If the new pipeline fails:

1. **Revert to old deploy.yml** temporarily
2. **Fix issues** in feature branch
3. **Test again** before re-enabling

## 📞 **Support**

- **Pipeline fails?** Check logs in GitHub Actions
- **Deployment issues?** Verify Azure permissions
- **Secrets problems?** Confirm all secrets are set
- **Performance degradation?** Check performance baselines

This migration transforms your CI/CD from independent workflows to a proper orchestrated pipeline, ensuring safety, efficiency, and reliability.
