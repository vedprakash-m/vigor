#!/bin/bash
# Enhanced Local E2E Validation Script v2
# This script includes critical dependency validation to prevent CI/CD failures

set -e

echo "🔧 Enhanced Local E2E Validation for Vigor Project v2"
echo "====================================================="

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
    print_error "DEPENDENCY INSTALLATION FAILED! This would fail in CI/CD."
    echo "================= PIP INSTALL LOG ================="
    cat /tmp/pip_install.log
    echo "=================================================="
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
print_step "Running flake8 linting"
if flake8 .; then
    print_success "Flake8 linting passed"
else
    print_error "Flake8 linting failed"
    exit 1
fi

print_step "Running MyPy type checking"
mypy . --ignore-missing-imports || {
    print_warning "MyPy found type issues (not blocking)"
}

print_step "Running Safety vulnerability check"
if safety check; then
    print_success "Safety vulnerability check passed"
else
    print_error "Safety found vulnerabilities in dependencies"
    exit 1
fi

cd ..

# Step 2: Run Tests
if [ "$SKIP_TESTS" = false ]; then
    print_step "Running Backend Tests"
    cd backend
    pytest --cov=. --cov-report=term-missing --cov-fail-under=40 || {
        print_error "Backend tests failed or coverage below 40%"
        exit 1
    }
    print_success "Backend tests passed with adequate coverage"
    cd ..
fi

# Final success message
print_success "All validations passed! Ready for CI/CD deployment."
echo "🎉 Enhanced Local Validation Complete!"
echo "======================================"
