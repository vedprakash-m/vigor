# CI/CD Remediation Implementation Guide

## 🎯 Objective

Transform from complex enterprise CI/CD to cost-optimized single-slot deployment strategy.

## 📋 Implementation Steps

### Phase 1: Pipeline Simplification ✅

#### 1.1 Created Simple Pipeline

- ✅ Created `.github/workflows/simple-deploy.yml`
- ✅ Disabled complex pipeline in `ci-cd-pipeline.yml`
- ✅ Direct production deployment (no staging)
- ✅ Combined quality checks
- ✅ Simple health verification

#### 1.2 Infrastructure Optimization

- ✅ Created `infrastructure/bicep/cost-optimized.bicep`
- ✅ Single resource group strategy
- ✅ No staging slots
- ✅ Basic SKUs for cost optimization

### Phase 2: Remove Staging Dependencies (30 minutes)

#### 2.1 Clean Up Staging Scripts

```bash
# Remove staging-specific scripts
rm -f scripts/setup-staging-slot.sh
rm -f scripts/verify-staging.sh

# Update health check to remove staging references
sed -i '' 's/staging\.azurewebsites\.net/azurewebsites\.net/g' scripts/health-check.sh
```

#### 2.2 Update Environment Configuration

```bash
# Remove staging environment from GitHub
# Go to Settings > Environments > Delete "staging"

# Keep only "production" environment
```

#### 2.3 Clean Workflow Directory

```bash
# Archive complex workflows
mkdir -p .github/workflows/legacy/
mv .github/workflows/ci-cd-pipeline.yml .github/workflows/legacy/
mv .github/workflows/preview-environment.yml .github/workflows/legacy/
mv .github/workflows/cleanup-preview-environment.yml .github/workflows/legacy/
```

### Phase 3: Cost Validation (15 minutes)

#### 3.1 Resource Cost Check

```bash
# Deploy cost-optimized infrastructure
az deployment group create \
  --resource-group vigor-rg \
  --template-file infrastructure/bicep/cost-optimized.bicep \
  --parameters @infrastructure/parameters/production.json
```

#### 3.2 Validate Single Slot

```bash
# Verify no staging slot exists
az webapp deployment slot list \
  --name vigor-backend \
  --resource-group vigor-rg

# Should return empty array: []
```

## 🔧 Testing Instructions

### Test 1: Pipeline Execution

```bash
# Push a change to trigger simplified pipeline
git add .
git commit -m "test: trigger simplified pipeline"
git push origin main

# Should see:
# 1. Quality Checks (combined) ✅
# 2. Deploy Production (direct) ✅
# 3. Verify Deployment (simple) ✅
```

### Test 2: Cost Verification

```bash
# Check current Azure costs
az consumption usage list \
  --start-date $(date -d '30 days ago' '+%Y-%m-%d') \
  --end-date $(date '+%Y-%m-%d') \
  --billing-period-name $(az billing period list --query '[0].name' -o tsv)

# Should show ~$43/month total
```

### Test 3: Single Slot Confirmation

```bash
# Verify direct production deployment
curl -f https://vigor-backend.azurewebsites.net/health

# Should return 200 OK without staging URL
```

## 📊 Expected Outcomes

### Before (Complex Pipeline)

- ❌ Staging slots: +$13/month
- ❌ Staging environment: +$25/month
- ❌ Complex monitoring: +$5/month
- ❌ Multiple RGs: +$10/month
- **Total**: ~$96/month

### After (Simplified Pipeline)

- ✅ Single production slot: $13/month
- ✅ Single basic PostgreSQL: $25/month
- ✅ Basic Key Vault: $3/month
- ✅ Standard storage: $2/month
- **Total**: ~$43/month (**45% cost reduction**)

## 🚨 Critical Success Factors

1. **No Staging**: Direct to production deployment
2. **Single Resource Group**: All resources in `vigor-rg`
3. **Basic SKUs**: B1 App Service, Basic PostgreSQL
4. **Simplified Monitoring**: Single health check only
5. **Static Naming**: No environment suffixes

## 🔄 Rollback Plan

If issues occur:

```bash
# Re-enable complex pipeline
git checkout HEAD~1 -- .github/workflows/ci-cd-pipeline.yml

# Restore staging slot
az webapp deployment slot create \
  --name vigor-backend \
  --resource-group vigor-rg \
  --slot staging

# Push rollback
git commit -m "rollback: restore complex pipeline"
git push origin main
```

## ✅ Validation Checklist

- [ ] Simple pipeline executes successfully
- [ ] No staging slots exist
- [ ] Production deployment works
- [ ] Health check passes
- [ ] Monthly cost ≤ $50
- [ ] All tests pass
- [ ] No environment-specific code

## 📞 Next Steps

1. Deploy the simplified pipeline
2. Monitor first production deployment
3. Validate cost reduction in Azure billing
4. Update documentation to reflect single-slot strategy
5. Remove all staging references from codebase
