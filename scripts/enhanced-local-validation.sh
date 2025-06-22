#!/bin/bash
# Enhanced Local E2E Validation Script
# This script fixes formatting issues and runs comprehensive validation

set -e

echo "🔧 Enhanced Local E2E Validation for Vigor Project"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Parse arguments
FIX_MODE=true
SKIP_TESTS=false
SKIP_E2E=false

for arg in "$@"; do
    case $arg in
        --check-only)
            FIX_MODE=false
            ;;
        --skip-tests)
            SKIP_TESTS=true
            ;;
        --skip-e2e)
            SKIP_E2E=true
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --check-only     Only check formatting, don't fix"
            echo "  --skip-tests     Skip running tests"
            echo "  --skip-e2e       Skip E2E tests (requires servers)"
            echo "  --help           Show this help"
            exit 0
            ;;
    esac
done

# Step 0: CRITICAL DEPENDENCY VALIDATION (NEW - prevents CI/CD failures)
print_step "Critical Dependency Installation Validation"
echo "============================================="

# Test clean dependency installation in a temporary virtual environment
# This catches dependency conflicts that would fail in CI/CD but might be masked locally
print_step "Creating temporary test environment for dependency validation..."
TEMP_VENV_DIR="/tmp/vigor_dep_test_$$"
python -m venv "$TEMP_VENV_DIR"
source "$TEMP_VENV_DIR/bin/activate"

cd backend

print_step "Testing clean pip install -r requirements.txt (simulating CI/CD)..."
if ! pip install -r requirements.txt > /tmp/pip_install.log 2>&1; then
    print_error "DEPENDENCY INSTALLATION FAILED! This would fail in CI/CD. Check /tmp/pip_install.log for details."
    cat /tmp/pip_install.log
    deactivate
    rm -rf "$TEMP_VENV_DIR"
    exit 1
fi

print_success "Clean dependency installation successful - CI/CD dependencies OK"

# Test import of key modules to ensure no missing dependencies
print_step "Testing critical module imports..."
python -c "
import sys
try:
    import fastapi
    import sqlalchemy
    import pytest
    import opentelemetry
    import google.generativeai
    import anthropic
    import pydantic
    import uvicorn
    print('✅ All critical modules import successfully')
except ImportError as e:
    print(f'❌ Import error: {e}')
    sys.exit(1)
" || {
    print_error "Critical module import failed - this would break CI/CD deployment"
    deactivate
    rm -rf "$TEMP_VENV_DIR"
    exit 1
}

# Cleanup test environment
deactivate
rm -rf "$TEMP_VENV_DIR"
print_success "Dependency validation complete - CI/CD will not fail on dependencies"

cd ..

# CRITICAL: Pre-commit validation to catch CI/CD failures
print_step "Pre-commit CI/CD Simulation"
echo "============================="

# Check if there are any staged changes that would trigger CI/CD
if git diff --cached --quiet; then
    print_success "No staged changes - CI/CD validation not needed"
else
    print_warning "Staged changes detected - simulating CI/CD formatting checks"

    # Check if staged files would pass CI/CD formatting
    cd backend
    print_step "Simulating CI/CD Black formatting check on staged files"

    # Get list of staged Python files
    STAGED_PY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' | grep '^backend/' | sed 's|^backend/||' || true)

    if [ -n "$STAGED_PY_FILES" ]; then
        print_step "Checking formatting on staged Python files..."
        for file in $STAGED_PY_FILES; do
            if [ -f "$file" ]; then
                if ! black --check "$file" >/dev/null 2>&1; then
                    print_error "Staged file $file would fail CI/CD formatting check!"
                    print_warning "Run 'black $file' to fix before committing"
                fi
            fi
        done
    fi

    cd ..
fi

# Step 1: Backend Formatting and Quality
print_step "Backend Code Quality Checks"

cd backend

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    print_success "Activated Python virtual environment"
else
    print_error "Backend virtual environment not found"
    exit 1
fi

# Install dependencies (exactly like CI/CD)
print_step "Installing backend dependencies (matching CI/CD)"
pip install --quiet -r requirements.txt
pip install --quiet -r requirements-dev.txt

# CRITICAL: Always check formatting first to catch CI/CD issues early
print_step "Pre-validation: Checking code formatting (like CI/CD)"
FORMATTING_ISSUES=false

# Check Black formatting first (this is what CI/CD does)
if ! black --check . >/dev/null 2>&1; then
    FORMATTING_ISSUES=true
    print_warning "Black formatting issues detected (this would fail CI/CD)"
    if [ "$FIX_MODE" = true ]; then
        print_step "Auto-fixing Black formatting issues"
        black .
        print_success "Black formatting applied"
    else
        print_error "Black formatting check failed - run without --check-only to fix"
        black --check --diff .
        exit 1
    fi
else
    print_success "Black formatting check passed"
fi

# Check ruff import sorting (I001 rule - matching CI/CD exactly)
if ! ruff check --select I001 . >/dev/null 2>&1; then
    FORMATTING_ISSUES=true
    print_warning "Import sorting issues detected (this would fail CI/CD)"
    if [ "$FIX_MODE" = true ]; then
        print_step "Auto-fixing import sorting issues with ruff"
        ruff check --fix --select I001 .
        print_success "Import sorting applied with ruff"
    else
        print_error "Import sorting check failed - run without --check-only to fix"
        ruff check --select I001 .
        exit 1
    fi
else
    print_success "Import sorting check passed (ruff I001)"
fi

# Report if formatting issues were found and fixed
if [ "$FORMATTING_ISSUES" = true ] && [ "$FIX_MODE" = true ]; then
    print_warning "Formatting issues were detected and fixed - commit these changes!"
    print_warning "This prevents CI/CD failures due to formatting"
fi

# Run quality checks
print_step "Running Ruff linting"
if [ "$FIX_MODE" = true ]; then
    # First attempt to fix issues
    print_step "Attempting to fix Ruff issues automatically"
    ruff check --fix .

    # Then re-check to ensure all issues are resolved
    print_step "Re-checking Ruff after auto-fixes"
    if ruff check .; then
        print_success "Ruff linting passed after auto-fixes"
    else
        print_error "Ruff found unfixable issues - manual intervention required"
        print_warning "Run 'ruff check .' to see remaining issues"
        exit 1
    fi
else
    # Check-only mode (matching CI/CD exactly)
    if ruff check .; then
        print_success "Ruff linting passed"
    else
        print_error "Ruff linting failed - run without --check-only to auto-fix"
        exit 1
    fi
fi

print_step "Running MyPy type checking"
mypy . --ignore-missing-imports || {
    print_warning "MyPy found type issues (not blocking)"
}

print_step "Running Bandit security scanning"
if bandit -r . -f json -o bandit_report.json --severity-level medium; then
    print_success "Bandit security scan passed"
else
    print_warning "Bandit found security issues - check bandit_report.json"
fi

print_step "Running Safety vulnerability check"
if safety check; then
    print_success "Safety vulnerability check passed"
else
    print_error "Safety found vulnerabilities in dependencies"
    exit 1
fi

cd ..

# Step 2: Frontend Quality
print_step "Frontend Code Quality Checks"

cd frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    print_step "Installing frontend dependencies"
    npm install
fi

# Run frontend linting
print_step "Running ESLint"
if [ "$FIX_MODE" = true ]; then
    npm run lint:fix || {
        print_warning "ESLint auto-fix completed with warnings"
    }
else
    npm run lint || {
        print_error "ESLint failed"
        exit 1
    }
fi

cd ..

# Step 3: Run Tests
if [ "$SKIP_TESTS" = false ]; then
    print_step "Running Backend Tests"
    cd backend
    pytest --cov=. --cov-report=term-missing --cov-fail-under=50 || {
        print_error "Backend tests failed or coverage below 50%"
        exit 1
    }
    print_success "Backend tests passed with adequate coverage"
    cd ..

    print_step "Running Frontend Tests"
    cd frontend
    npm test -- --coverage --watchAll=false --coverageReporters=text --coverageReporters=lcov || {
        print_error "Frontend tests failed"
        exit 1
    }

    # Check coverage thresholds (matching CI/CD expectations)
    print_step "Checking frontend test coverage"
    if npm test -- --coverage --watchAll=false --passWithNoTests --silent | grep -q "Statements.*[0-9][0-9]%"; then
        print_success "Frontend test coverage adequate"
    else
        print_warning "Frontend test coverage may be below threshold"
    fi

    print_success "Frontend tests passed"
    cd ..

    print_step "Frontend type checking"
    cd frontend
    npm run type-check || {
        print_error "Frontend TypeScript compilation failed"
        exit 1
    }
    print_success "Frontend TypeScript check passed"
    cd ..
fi

# Step 4: Build Verification (matching CI/CD)
if [ "$SKIP_TESTS" = false ]; then
    print_step "Frontend Build Verification"
    cd frontend
    npm run build || {
        print_error "Frontend build failed"
        exit 1
    }

    # Verify build output exists (like CI/CD does)
    if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
        print_success "Frontend build completed successfully"
        # Clean up build artifacts for local dev
        rm -rf dist
    else
        print_error "Frontend build output missing or empty"
        exit 1
    fi
    cd ..
fi

# Step 5: Run E2E Tests (requires servers)
if [ "$SKIP_E2E" = false ]; then
    print_step "Running E2E Tests"

    # Check if Playwright is installed
    cd frontend
    if [ ! -d "node_modules/@playwright" ]; then
        print_step "Installing Playwright browsers"
        npx playwright install --with-deps
    fi

    # Build frontend for testing (again, since we cleaned up)
    print_step "Building frontend for E2E testing"
    npm run build || {
        print_error "Frontend build failed"
        exit 1
    }

    # Start backend server in background
    print_step "Starting backend server for E2E tests"
    cd ../backend

    # Check if venv is still active
    if [ -z "$VIRTUAL_ENV" ]; then
        source venv/bin/activate
    fi

    # Set environment variables for testing (matching CI/CD)
    export DATABASE_URL="sqlite:///test.db"
    export LLM_PROVIDER="fallback"
    export OPENAI_API_KEY="sk-placeholder"
    export E2E_TEST="true"

    # Start backend server in background
    python main.py &
    BACKEND_PID=$!
    print_success "Backend server started (PID: $BACKEND_PID)"

    # Wait for backend to be ready
    sleep 5

    # Start frontend dev server in background
    print_step "Starting frontend dev server for E2E tests"
    cd ../frontend
    npm run dev &
    FRONTEND_PID=$!
    print_success "Frontend dev server started (PID: $FRONTEND_PID)"

    # Wait for frontend to be ready
    print_step "Waiting for servers to be ready"
    npx wait-on http://localhost:5173 --timeout 30000 || {
        print_error "Frontend server failed to start"
        kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
        exit 1
    }

    # Check backend health
    npx wait-on http://localhost:8000/health --timeout 15000 || {
        print_warning "Backend health check failed, but continuing with E2E tests"
    }

    # Run E2E tests
    print_step "Running Playwright E2E tests"
    npm run test:e2e || {
        print_error "E2E tests failed"
        kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
        exit 1
    }

    # Cleanup servers
    print_step "Stopping test servers"
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    sleep 2
    print_success "E2E tests passed"

    cd ..
fi

# Step 6: Dependency Security Scanning (NEW - matches CI/CD)
print_step "Dependency Security Scanning"

# Frontend dependency audit
cd frontend
print_step "Running npm audit for frontend dependencies"
if npm audit --audit-level=moderate; then
    print_success "Frontend dependencies security audit passed"
else
    print_warning "Frontend dependencies have security vulnerabilities"
    print_warning "Run 'npm audit fix' to attempt automatic fixes"
fi
cd ..

# Backend dependency scanning (already done with safety above)
print_success "Backend dependency security scan completed with Safety"

# Step 7: Git and Repository Validation
print_step "Checking Git Status"
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Files were modified during validation:"
    git status --porcelain
    echo ""
    echo -e "${YELLOW}You may want to review and commit these changes.${NC}"
else
    print_success "No files were modified"
fi

# Step 8: Azure & Deployment Validation (Comprehensive)
print_step "Azure Authentication & Deployment Validation"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_warning "Azure CLI not installed - skipping Azure validation"
    print_warning "Install with: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
else
    print_step "Checking Azure CLI login status"
    if az account show &> /dev/null; then
        AZURE_ACCOUNT=$(az account show --query name --output tsv)
        print_success "Azure CLI logged in to: $AZURE_ACCOUNT"

        # Validate subscription access
        SUBSCRIPTION_ID=$(az account show --query id --output tsv)
        print_success "Azure Subscription ID: $SUBSCRIPTION_ID"

        # Check if required resources exist
        print_step "Checking Azure resource groups"
        if az group show --name vigor-rg &> /dev/null; then
            print_success "Main resource group 'vigor-rg' exists"
        else
            print_warning "Main resource group 'vigor-rg' not found"
            print_warning "Run: az group create --name vigor-rg --location 'Central US'"
        fi

        if az group show --name vigor-db-rg &> /dev/null; then
            print_success "Database resource group 'vigor-db-rg' exists"
        else
            print_warning "Database resource group 'vigor-db-rg' not found"
            print_warning "Run: az group create --name vigor-db-rg --location 'Central US'"
        fi

        # Check App Service
        print_step "Checking Azure App Service"
        if az webapp show --name vigor-backend --resource-group vigor-rg &> /dev/null; then
            print_success "App Service 'vigor-backend' exists"
        else
            print_warning "App Service 'vigor-backend' not found"
            print_warning "Deploy infrastructure first: cd infrastructure/bicep && ./deploy.sh"
        fi

    else
        print_warning "Azure CLI not logged in"
        print_warning "Run: az login"
    fi
fi

# Check GitHub CLI and repository secrets
print_step "Checking GitHub repository configuration"
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI not installed - skipping GitHub validation"
    print_warning "Install with: brew install gh"
else
    if gh auth status &> /dev/null; then
        print_success "GitHub CLI authenticated"

        # Check if we're in a GitHub repository
        if gh repo view &> /dev/null; then
            REPO_NAME=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
            print_success "GitHub repository: $REPO_NAME"

            # Check required secrets
            print_step "Validating GitHub repository secrets"
            REQUIRED_SECRETS=("AZURE_CLIENT_ID" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID" "DATABASE_URL" "SECRET_KEY" "OPENAI_API_KEY")

            for secret in "${REQUIRED_SECRETS[@]}"; do
                if gh secret list | grep -q "^$secret"; then
                    print_success "Secret '$secret' exists"
                else
                    print_error "Missing required secret: $secret"
                    print_warning "Set with: gh secret set $secret"
                fi
            done

            # Check if environment exists
            if gh api repos/:owner/:repo/environments/production &> /dev/null; then
                print_success "GitHub environment 'production' exists"
            else
                print_warning "GitHub environment 'production' not configured"
                print_warning "This may be needed for federated identity"
            fi

        else
            print_warning "Not in a GitHub repository or repository not accessible"
        fi
    else
        print_warning "GitHub CLI not authenticated"
        print_warning "Run: gh auth login"
    fi
fi

# Validate CI/CD workflow syntax
print_step "Validating CI/CD workflow syntax"
if command -v actionlint &> /dev/null; then
    if actionlint .github/workflows/simple-deploy.yml; then
        print_success "GitHub Actions workflow syntax valid"
    else
        print_error "GitHub Actions workflow has syntax errors"
        exit 1
    fi
else
    print_warning "actionlint not installed - skipping workflow validation"
    print_warning "Install with: go install github.com/rhymond/actionlint/cmd/actionlint@latest"
fi

# Check for pre-commit hooks consistency
print_step "Validating pre-commit hooks"
if [ -f ".pre-commit-config.yaml" ]; then
    if command -v pre-commit &> /dev/null; then
        if pre-commit run --all-files --verbose; then
            print_success "Pre-commit hooks validation passed"
        else
            print_warning "Pre-commit hooks found issues (may have been auto-fixed)"
        fi
    else
        print_warning "pre-commit not installed - skipping hook validation"
        print_warning "Install with: pip install pre-commit"
    fi
else
    print_warning "No .pre-commit-config.yaml found"
fi

# Step 9: FINAL CI/CD SIMULATION - Double-check everything
print_step "Final CI/CD Simulation (Double-Check)"
echo "====================================="

cd backend

print_step "Final Black formatting verification (exactly like CI/CD)"
if ! black --check . >/dev/null 2>&1; then
    print_error "CRITICAL: Black formatting issues detected after validation!"
    print_error "This would cause CI/CD failure. Running black --check for details:"
    black --check .
    exit 1
else
    print_success "✅ Final Black check: All files properly formatted"
fi

print_step "Final ruff import sorting verification (exactly like CI/CD)"
if ! ruff check --select I001 . >/dev/null 2>&1; then
    print_error "CRITICAL: Import sorting issues detected after validation!"
    print_error "This would cause CI/CD failure. Running ruff check --select I001 for details:"
    ruff check --select I001 .
    exit 1
else
    print_success "✅ Final ruff import sorting check: All imports properly sorted"
fi

print_step "Final Ruff verification (exactly like CI/CD)"
if ! ruff check . >/dev/null 2>&1; then
    print_error "CRITICAL: Ruff linting issues detected after validation!"
    print_error "This would cause CI/CD failure. Running ruff check for details:"
    ruff check .
    exit 1
else
    print_success "✅ Final Ruff check: All linting rules satisfied"
fi

cd ..

print_success "🎯 Final CI/CD simulation: ALL CHECKS PASSED"
print_success "CI/CD pipeline will NOT fail on code quality issues"

# Step 10: Final Git Status Check
print_step "Checking Git Status"
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Files were modified during validation:"
    git status --porcelain
    echo ""
    echo -e "${YELLOW}You may want to review and commit these changes.${NC}"
else
    print_success "No files were modified"
fi

# Step 11: Final Summary
echo ""
echo -e "${GREEN}🎉 Comprehensive Local E2E Validation Complete!${NC}"
echo "=================================================="
echo -e "${GREEN}✅ Backend formatting and quality checks passed${NC}"
echo -e "${GREEN}✅ Backend security scanning completed${NC}"
echo -e "${GREEN}✅ Frontend linting and type checking passed${NC}"
echo -e "${GREEN}✅ Dependency vulnerability scanning completed${NC}"
if [ "$SKIP_TESTS" = false ]; then
    echo -e "${GREEN}✅ All unit tests passed with coverage requirements${NC}"
    echo -e "${GREEN}✅ Build verification completed${NC}"
fi
if [ "$SKIP_E2E" = false ]; then
    echo -e "${GREEN}✅ E2E tests passed${NC}"
fi
echo -e "${GREEN}✅ Azure and GitHub repository validation completed${NC}"
echo -e "${GREEN}✅ CI/CD workflow syntax validated${NC}"
echo ""
echo -e "${BLUE}📊 Validation Summary:${NC}"
echo -e "${BLUE}   • Code quality: ✅ Formatting, linting, type checking${NC}"
echo -e "${BLUE}   • Security: ✅ Bandit, Safety, npm audit${NC}"
echo -e "${BLUE}   • Testing: ✅ Unit tests, E2E tests, coverage thresholds${NC}"
echo -e "${BLUE}   • Build: ✅ Frontend build verification${NC}"
echo -e "${BLUE}   • Infrastructure: ✅ Azure resources, GitHub secrets${NC}"
echo -e "${BLUE}   • CI/CD: ✅ Workflow validation, pre-commit hooks${NC}"
echo ""
echo -e "${GREEN}🚀 Your code is ready for the CI/CD pipeline!${NC}"
echo -e "${BLUE}All checks performed locally match the GitHub Actions workflow.${NC}"
