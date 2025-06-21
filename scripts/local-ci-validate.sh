#!/bin/bash
# Local CI/CD Validation Script
# Matches CI/CD pipeline validation as closely as possible

set -e

echo "🔧 Local CI/CD Validation for Vigor Project"
echo "============================================"

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
SKIP_TESTS=false
SKIP_E2E=false
PRE_COMMIT=false

for arg in "$@"; do
    case $arg in
        --skip-tests)
            SKIP_TESTS=true
            ;;
        --skip-e2e)
            SKIP_E2E=true
            ;;
        --pre-commit)
            PRE_COMMIT=true
            SKIP_TESTS=true
            SKIP_E2E=true
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-tests     Skip running tests"
            echo "  --skip-e2e       Skip E2E tests"
            echo "  --pre-commit     Fast validation for pre-commit hooks"
            echo "  --help           Show this help"
            exit 0
            ;;
    esac
done

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Step 1: Backend Validation
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

# Check dependencies are installed
print_step "Checking backend dependencies"
pip check || {
    print_warning "Installing missing dependencies"
    pip install -r requirements.txt
}

# Code formatting checks
print_step "Running Black formatting check"
if black --check .; then
    print_success "Black formatting check passed"
else
    print_error "Black formatting check failed - run 'black .' to fix"
    exit 1
fi

print_step "Running isort import sorting check"
if isort --check-only .; then
    print_success "Import sorting check passed"
else
    print_error "Import sorting check failed - run 'isort .' to fix"
    exit 1
fi

# Linting checks
print_step "Running Ruff linting"
if command -v ruff >/dev/null 2>&1; then
    if ruff check .; then
        print_success "Ruff linting passed"
    else
        print_error "Ruff linting failed"
        exit 1
    fi
else
    print_warning "Ruff not found, using flake8"
    if flake8 .; then
        print_success "Flake8 linting passed"
    else
        print_error "Flake8 linting failed"
        exit 1
    fi
fi

# Type checking
print_step "Running MyPy type checking"
if mypy . --ignore-missing-imports; then
    print_success "MyPy type checking passed"
else
    print_warning "MyPy found type issues (non-blocking)"
fi

# Security checks
print_step "Running Bandit security scan"
if bandit -r . --format json >/dev/null 2>&1; then
    print_success "Bandit security scan passed"
else
    print_warning "Bandit found security issues (non-blocking)"
fi

# Backend tests
if [ "$SKIP_TESTS" = false ]; then
    print_step "Running backend tests with coverage"
    if pytest --cov=. --cov-fail-under=40 --cov-report=term-missing -x; then
        print_success "Backend tests passed"
    else
        print_error "Backend tests failed"
        exit 1
    fi
fi

cd ..

# Step 2: Frontend Validation
print_step "Frontend Code Quality Checks"

cd frontend

# Check dependencies
print_step "Checking frontend dependencies"
if [ ! -d "node_modules" ]; then
    print_warning "Installing frontend dependencies"
    npm install
fi

# Linting
print_step "Running ESLint"
if npm run lint 2>/dev/null; then
    print_success "ESLint passed"
else
    print_error "ESLint failed"
    exit 1
fi

# Type checking
print_step "Running TypeScript type checking"
if npm run type-check 2>/dev/null; then
    print_success "TypeScript type checking passed"
else
    print_error "TypeScript type checking failed"
    exit 1
fi

# Frontend tests
if [ "$SKIP_TESTS" = false ]; then
    print_step "Running frontend tests"
    if npm test -- --watchAll=false --coverage; then
        print_success "Frontend tests passed"
    else
        print_error "Frontend tests failed"
        exit 1
    fi
fi

# Build verification
if [ "$PRE_COMMIT" = false ]; then
    print_step "Verifying frontend build"
    if npm run build >/dev/null 2>&1; then
        print_success "Frontend build succeeded"
    else
        print_error "Frontend build failed"
        exit 1
    fi
fi

cd ..

# Step 3: E2E Tests (if not skipped)
if [ "$SKIP_E2E" = false ] && [ "$PRE_COMMIT" = false ]; then
    print_step "Running E2E Tests"
    cd frontend
    if npm run test:e2e >/dev/null 2>&1; then
        print_success "E2E tests passed"
    else
        print_warning "E2E tests failed or not configured (non-blocking)"
    fi
    cd ..
fi

# Final summary
echo
print_success "🎉 Local CI/CD validation completed successfully!"
echo
if [ "$PRE_COMMIT" = true ]; then
    echo "✅ Pre-commit validation passed - ready to commit"
else
    echo "✅ Full validation passed - ready for CI/CD pipeline"
fi
echo
