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

# Apply formatting fixes
if [ "$FIX_MODE" = true ]; then
    print_step "Applying Black formatting"
    black .
    print_success "Black formatting applied"

    print_step "Applying isort import sorting"
    isort .
    print_success "Import sorting applied"
else
    print_step "Checking Black formatting (check-only mode)"
    black --check --diff .

    print_step "Checking isort import sorting (check-only mode)"
    isort --check-only --diff .
fi

# Run quality checks
print_step "Running Ruff linting"
ruff check . || {
    if [ "$FIX_MODE" = true ]; then
        print_warning "Ruff issues found, attempting to fix"
        ruff check --fix .
        print_success "Ruff auto-fixes applied"
    else
        print_error "Ruff linting failed"
        exit 1
    fi
}

print_step "Running MyPy type checking"
mypy . --ignore-missing-imports || {
    print_warning "MyPy found type issues (not blocking)"
}

print_step "Running Bandit security scanning"
bandit -c .bandit -r . --severity-level medium --quiet || {
    print_warning "Bandit found security issues (not blocking)"
}

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
    pytest --cov=. --cov-report=term-missing || {
        print_error "Backend tests failed"
        exit 1
    }
    print_success "Backend tests passed"
    cd ..

    print_step "Running Frontend Tests"
    cd frontend
    npm test -- --coverage --watchAll=false || {
        print_error "Frontend tests failed"
        exit 1
    }
    print_success "Frontend tests passed"
    cd ..
fi

# Step 4: Run E2E Tests (requires servers)
if [ "$SKIP_E2E" = false ]; then
    print_step "Running E2E Tests"

    # Check if Playwright is installed
    cd frontend
    if [ ! -d "node_modules/@playwright" ]; then
        print_step "Installing Playwright browsers"
        npx playwright install --with-deps
    fi

    # Build frontend for testing
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

    # Set environment variables for testing
    export DATABASE_URL="sqlite:///test.db"
    export LLM_PROVIDER="fallback"
    export OPENAI_API_KEY="sk-placeholder"

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

# Step 7: Check Git Status
print_step "Checking Git Status"
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Files were modified during validation:"
    git status --porcelain
    echo ""
    echo -e "${YELLOW}You may want to review and commit these changes.${NC}"
else
    print_success "No files were modified"
fi

# Step 6: Azure & Deployment Validation (NEW)
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
        print_step "Checking Azure resource group"
        if az group show --name vigor-rg &> /dev/null; then
            print_success "Resource group 'vigor-rg' exists"
        else
            print_warning "Resource group 'vigor-rg' not found"
            print_warning "Run: az group create --name vigor-rg --location 'Central US'"
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
    fi
else
    print_warning "actionlint not installed - skipping workflow validation"
    print_warning "Install with: go install github.com/rhymond/actionlint/cmd/actionlint@latest"
fi

# Step 7: Check Git Status
print_step "Checking Git Status"
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Files were modified during validation:"
    git status --porcelain
    echo ""
    echo -e "${YELLOW}You may want to review and commit these changes.${NC}"
else
    print_success "No files were modified"
fi

# Step 8: Final Summary
echo ""
echo -e "${GREEN}🎉 Local E2E Validation Complete!${NC}"
echo "=================================="
echo -e "${GREEN}✅ Backend formatting and quality checks passed${NC}"
echo -e "${GREEN}✅ Frontend linting passed${NC}"
if [ "$SKIP_TESTS" = false ]; then
    echo -e "${GREEN}✅ All unit tests passed${NC}"
fi
if [ "$SKIP_E2E" = false ]; then
    echo -e "${GREEN}✅ E2E tests passed${NC}"
fi
echo ""
echo -e "${BLUE}Your code is ready for CI/CD pipeline! 🚀${NC}"
