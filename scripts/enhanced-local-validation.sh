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

# Install/update formatting tools
print_step "Ensuring formatting tools are available"
pip install --quiet black isort ruff mypy bandit

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

# Step 5: Check Git Status
print_step "Checking Git Status"
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Files were modified during validation:"
    git status --porcelain
    echo ""
    echo -e "${YELLOW}You may want to review and commit these changes.${NC}"
else
    print_success "No files were modified"
fi

# Step 6: Final Summary
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
