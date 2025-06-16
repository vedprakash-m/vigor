# CI/CD Pipeline Migration Checklist

## ✅ **Completed Steps**

- [x] **Backup old workflows** to `.github/workflows/legacy/`
- [x] **Disable old workflows** (renamed to `.disabled`)
- [x] **Create unified DAG pipeline** (`ci-cd-pipeline.yml`)
- [x] **Push migration commit** to trigger new pipeline
- [x] **Create staging slot setup script**

## 🔄 **Next Steps** (In Progress)

### **1. Monitor New Pipeline Run**
- [ ] Check GitHub Actions for new pipeline execution
- [ ] Verify change detection works correctly
- [ ] Confirm parallel quality checks run properly

### **2. GitHub Environment Setup** (Manual)
- [ ] Go to Repository Settings → Environments
- [ ] Create "staging" environment
- [ ] Create "production" environment with protection rules
- [ ] Configure environment secrets if needed

### **3. Azure Staging Slot Setup** (Run Script)
```bash
./scripts/setup-staging-slot.sh
```
- [ ] Verify Azure CLI is logged in
- [ ] Run the setup script
- [ ] Confirm staging slot is created

### **4. Secrets Verification**
Ensure these secrets exist in GitHub Settings → Secrets:
- [ ] `AZURE_CLIENT_ID`
- [ ] `AZURE_TENANT_ID`
- [ ] `AZURE_SUBSCRIPTION_ID`
- [ ] `DATABASE_URL`
- [ ] `SECRET_KEY`
- [ ] `OPENAI_API_KEY`
- [ ] `LLM_PROVIDER`
- [ ] `AZURE_KEY_VAULT_URL`

### **5. Pipeline Validation**
- [ ] Make a small test change (e.g., update README)
- [ ] Verify full pipeline runs end-to-end
- [ ] Check staging deployment works
- [ ] Confirm production deployment follows staging
- [ ] Test failure scenarios

### **6. Cleanup** (After Validation)
- [ ] Remove `.disabled` workflow files
- [ ] Update documentation
- [ ] Clean up legacy backups (optional)

## 🚨 **Rollback Plan** (If Needed)

If the new pipeline fails:
1. Rename `.disabled` files back to `.yml`
2. Temporarily disable `ci-cd-pipeline.yml`
3. Fix issues and retry

## 📊 **Expected Behavior**

### **On This Commit:**
- New pipeline should detect changes to workflows, docs, and scripts
- Should run quality checks for backend, frontend, and infrastructure
- Should skip deployment (if staging environment not configured yet)

### **Future Commits:**
- Smart change detection (only test modified components)
- Staging → Production deployment flow
- Automatic failure handling

## 🎯 **Success Criteria**

- [ ] New pipeline runs without errors
- [ ] Change detection works correctly
- [ ] Staging deployment successful
- [ ] Production deployment only after staging validation
- [ ] Old workflows completely replaced

---

**Current Status:** Migration in progress, monitoring first pipeline run.
