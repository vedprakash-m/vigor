#!/bin/bash
# Pre-deployment validation - comprehensive check before pushing to main
# This ensures CI/CD will succeed by validating all prerequisites

set -e

echo "🚀 Pre-Deployment Validation for Vigor"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

VALIDATION_ERRORS=0

check_error() {
    if [ $? -ne 0 ]; then
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "$1"
    else
        print_success "$1"
    fi
}

# 1. Code Quality Validation
print_step "Running enhanced local validation"
bash scripts/enhanced-local-validation.sh --check-only --skip-e2e
check_error "Code quality checks passed"

# 3. Build Validation
print_step "Validating production builds"

# Backend build validation
cd backend
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi
pip install -r requirements.txt > /dev/null 2>&1
check_error "Backend dependencies install successfully"

# Frontend build validation
cd ../frontend
npm ci > /dev/null 2>&1
check_error "Frontend dependencies install successfully"

npm run build > /dev/null 2>&1
check_error "Frontend builds successfully for production"
cd ..

# 2.5. CI/CD Environment Validation (NEW)
print_step "Validating CI/CD environment parity"

# Ensure backend tools match CI/CD expectations
cd backend
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi

# Check that all CI/CD tools are available
CI_TOOLS=("black" "isort" "ruff" "mypy" "bandit" "safety" "pytest")
for tool in "${CI_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "CI/CD tool '$tool' not available"
    fi
done

# Validate requirements-dev.txt has all tools
REQUIRED_IN_DEV_DEPS=("black" "isort" "ruff" "mypy" "bandit" "safety")
for tool in "${REQUIRED_IN_DEV_DEPS[@]}"; do
    if ! grep -q "^$tool==" requirements-dev.txt; then
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "Tool '$tool' missing from requirements-dev.txt"
    fi
done

cd ..

# 4. Azure Authentication Check
print_step "Validating Azure authentication"

if command -v az &> /dev/null; then
    if az account show &> /dev/null; then
        print_success "Azure CLI authenticated"
    else
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "Azure CLI not authenticated - run 'az login'"
    fi
else
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    print_error "Azure CLI not installed"
fi

# 5. GitHub Authentication Check
print_step "Validating GitHub authentication"

if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        print_success "GitHub CLI authenticated"
    else
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "GitHub CLI not authenticated - run 'gh auth login'"
    fi
else
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    print_error "GitHub CLI not installed"
fi

# 6. GitHub Secrets Validation
print_step "Validating GitHub repository secrets"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    REQUIRED_SECRETS=("AZURE_CLIENT_ID" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID" "DATABASE_URL" "SECRET_KEY" "OPENAI_API_KEY")

    for secret in "${REQUIRED_SECRETS[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            print_success "Secret '$secret' exists"
        else
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            print_error "Missing required secret: $secret"
        fi
    done
else
    print_warning "Skipping secret validation (GitHub CLI not available)"
fi

# 7. Azure Resources Check
print_step "Validating Azure resources"

if command -v az &> /dev/null && az account show &> /dev/null; then
    # Check resource group
    if az group show --name vigor-rg &> /dev/null; then
        print_success "Resource group 'vigor-rg' exists"
    else
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "Resource group 'vigor-rg' not found"
        print_warning "Create with: az group create --name vigor-rg --location 'Central US'"
    fi

    # Check App Service
    if az webapp show --name vigor-backend --resource-group vigor-rg &> /dev/null; then
        print_success "App Service 'vigor-backend' exists"
    else
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        print_error "App Service 'vigor-backend' not found"
        print_warning "Deploy infrastructure: cd infrastructure/bicep && ./deploy.sh"
    fi
else
    print_warning "Skipping Azure resource validation (Azure CLI not available)"
fi

# 8. Git Status Check
print_step "Checking Git status"

if [ -n "$(git status --porcelain)" ]; then
    print_warning "Uncommitted changes detected:"
    git status --porcelain
    print_warning "Consider committing changes before deployment"
else
    print_success "Working directory clean"
fi

# 9. Branch Check
print_step "Checking current branch"

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
    print_success "On main branch"
else
    print_warning "Not on main branch (current: $CURRENT_BRANCH)"
    print_warning "CI/CD only runs on main branch"
fi

# 10. CI/CD Workflow Validation
print_step "Validating CI/CD workflow"

if [ -f ".github/workflows/simple-deploy.yml" ]; then
    print_success "CI/CD workflow file exists"

    # Check for actionlint
    if command -v actionlint &> /dev/null; then
        if actionlint .github/workflows/simple-deploy.yml &> /dev/null; then
            print_success "CI/CD workflow syntax valid"
        else
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            print_error "CI/CD workflow has syntax errors"
        fi
    else
        print_warning "actionlint not installed - skipping workflow syntax check"
    fi
else
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    print_error "CI/CD workflow file not found"
fi

# Final Summary
echo ""
echo "======================================"
if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Pre-deployment validation PASSED!${NC}"
    echo -e "${GREEN}✅ Ready for CI/CD deployment${NC}"
    echo ""
    echo -e "${BLUE}To deploy:${NC}"
    echo "1. git add ."
    echo "2. git commit -m 'Your commit message'"
    echo "3. git push origin main"
    echo ""
    echo -e "${GREEN}CI/CD pipeline should succeed! 🚀${NC}"
    exit 0
else
    echo -e "${RED}❌ Pre-deployment validation FAILED!${NC}"
    echo -e "${RED}Found $VALIDATION_ERRORS error(s) that will cause CI/CD to fail${NC}"
    echo ""
    echo -e "${YELLOW}Fix the errors above before pushing to main${NC}"
    echo ""
    echo -e "${BLUE}Common fixes:${NC}"
    echo "• Run: ./scripts/setup-azure-federated-identity.sh"
    echo "• Run: az login"
    echo "• Run: gh auth login"
    echo "• Deploy infrastructure: cd infrastructure/bicep && ./deploy.sh"
    echo "• Set missing secrets: gh secret set SECRET_NAME"
    exit 1
fi
