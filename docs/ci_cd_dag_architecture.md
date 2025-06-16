# CI/CD Pipeline Architecture - DAG Workflow Design

## 🎯 **Problem Statement**

The previous CI/CD setup had workflows running independently without proper orchestration:

- Backend and frontend CI ran separately
- No dependency management between stages
- Deployment could happen even if tests were failing
- No staging environment validation
- Missing rollback coordination

## 🔄 **New DAG-Based Architecture**

### **Workflow Stages** (Sequential Dependencies)

```mermaid
graph TD
    A[Secret Scan] --> D[Detect Changes]
    B[Dependency Audit] --> D
    D --> E[Quality Checks]
    E --> F[Integration Tests]
    F --> G[Deploy Staging]
    G --> H[Verify Staging]
    H --> I[Deploy Production]
    I --> J[Verify Production]
    J --> K[Post-Merge Monitor]

    %% Parallel execution within stages
    subgraph "Stage 0: Security & Compliance (Parallel)"
        A1[Secret Scanning<br/>Gitleaks + Trufflehog]
        A2[Dependency Audit<br/>Safety + NPM Audit]
    end

    subgraph "Stage 1: Change Detection"
        D1[Smart Path Detection<br/>Backend/Frontend/Infra/Docs]
    end

    subgraph "Stage 2: Quality Checks (Parallel)"
        E1[Backend Quality<br/>Black, MyPy, Tests, Coverage]
        E2[Frontend Quality<br/>ESLint, TypeScript, Jest, Build]
        E3[Infrastructure Validation<br/>Bicep Validation, ARM Templates]
    end

    subgraph "Stage 3: Integration"
        F1[E2E Tests<br/>Full Application Testing]
        F2[API Integration<br/>Service Communication]
    end

    subgraph "Stage 4: Staging Deployment"
        G1[Deploy to Staging Slot]
        H1[Health Checks<br/>API Endpoints, Database]
        H2[Smoke Tests<br/>Critical User Flows]
        H3[Performance Baseline<br/>Response Time Validation]
    end

    subgraph "Stage 5: Production Deployment"
        I1[Deploy to Production]
        J1[Production Health Checks]
        J2[Production Smoke Tests]
        J3[Performance Verification]
    end

    subgraph "Stage 6: Post-Deployment Monitoring"
        K1[10-Minute Health Window]
        K2[Performance Baseline Check]
        K3[Error Rate Monitoring]
    end

    subgraph "Stage 7: Reporting & Audit (Always Run)"
        L1[Test Coverage Report]
        L2[PR Audit Trail]
        L3[Workflow Health Check]
        L4[Failure Notifications]
    end
```

## 🚀 **Key Features**

### **1. Smart Change Detection**

- Uses `dorny/paths-filter` to detect what components changed
- Skips unnecessary jobs based on changed files
- Optimizes CI/CD runtime

### **2. Proper Dependencies**

```yaml
# Example: Integration tests only run after quality checks pass
integration-tests:
  needs: [backend-quality, frontend-quality]
  if: |
    always() &&
    (needs.backend-quality.result == 'success' || needs.backend-quality.result == 'skipped') &&
    (needs.frontend-quality.result == 'success' || needs.frontend-quality.result == 'skipped')
```

### **3. Staging Environment Validation**

- Deploys to staging slot first
- Runs comprehensive health checks
- Only promotes to production if staging passes

### **4. Parallel Execution Where Safe**

- Quality checks run in parallel (backend, frontend, infrastructure)
- Each component is independent during validation
- Saves time while maintaining safety

### **5. Comprehensive Failure Handling**

- Automatic issue creation on deployment failures
- Proper rollback mechanisms
- Performance monitoring

## 📊 **Benefits of DAG Approach**

### **Safety** 🛡️

- No deployment without passing tests
- Staging validation before production
- Proper dependency management

### **Efficiency** ⚡

- Parallel execution where possible
- Smart change detection
- Optimized resource usage

### **Visibility** 👁️

- Clear pipeline stages
- Easy to understand dependencies
- Better failure diagnosis

### **Reliability** 🔒

- Consistent deployment process
- Automated rollback triggers
- Performance baselines

## 🔧 **Configuration**

### **Required Secrets**

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
DATABASE_URL
SECRET_KEY
OPENAI_API_KEY
LLM_PROVIDER
AZURE_KEY_VAULT_URL
```

### **Environment Requirements**

- Staging and Production environments configured in GitHub
- Azure App Service with staging slots
- Proper RBAC permissions for service principal

## 📈 **Workflow Triggers**

1. **Push to main**: Full pipeline including deployment
2. **Push to develop**: Quality checks and integration tests only
3. **Pull Request**: Quality checks and integration tests
4. **Manual**: Full pipeline with manual approval gates

## 🎛️ **Rollback Strategy**

If production verification fails:

1. Automatic slot swap back to previous version
2. Issue creation for tracking
3. Notification to development team
4. Performance baseline comparison

## 📝 **Migration from Old Workflows**

1. **Backup existing workflows** (move to `.github/workflows/legacy/`)
2. **Deploy new unified pipeline**
3. **Test with feature branch**
4. **Monitor first production deployment**
5. **Remove legacy workflows** after validation

## 🔄 **Unified DAG Consolidation**

### **Previously Disparate Workflows** ❌
- `backend-ci.yml` - Backend quality checks
- `frontend-ci.yml` - Frontend quality checks
- `e2e-tests.yml` - End-to-end testing
- `deploy.yml` - Production deployment
- `test-coverage-report.yml` - Coverage aggregation
- `dependency-audit.yml` - Security auditing
- `secret-scan.yml` - Secret scanning
- `gitleaks.yml` - Git secret detection
- `post-merge-monitor.yml` - Post-deployment monitoring
- `pr-audit-trail.yml` - Pull request auditing
- `workflow-health-check.yml` - Pipeline health monitoring

### **Now: Single Unified Pipeline** ✅
All above functionality consolidated into `ci-cd-pipeline.yml` with proper DAG orchestration.

**Remaining Independent Workflows** (Non-CI/CD):
- Security automation workflows (auto-merge, auto-approve)
- Emergency rollback procedures
- Preview environment management
- Security disclosure workflows

This DAG-based approach ensures proper orchestration, safety, and efficiency in the CI/CD pipeline while maintaining fast feedback loops for developers.
