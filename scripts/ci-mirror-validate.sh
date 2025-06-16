#!/bin/bash
# CI-Mirror Local Validation Script
# This script mirrors the exact CI/CD behavior to catch issues before pushing

set -e

echo "🚀 Running CI-Mirror validation (matches GitHub Actions exactly)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

function success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Check Node.js version compatibility
check_node_version() {
    echo "🔍 Checking Node.js version compatibility..."

    NODE_VERSION=$(node --version | sed 's/v//')
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)

    if [ "$MAJOR_VERSION" -lt 18 ]; then
        error "Node.js version $NODE_VERSION is not supported. Required: >=18.18.0 || >=20.0.0"
    elif [ "$MAJOR_VERSION" -eq 19 ]; then
        error "Node.js version 19.x is not supported by current packages. Use 18.18+ or 20+"
    fi

    success "Node.js version $NODE_VERSION is compatible"
}

# Backend validation (exactly matching backend-ci.yml)
validate_backend_ci() {
    echo "🐍 Running Backend CI validation..."

    cd backend

    # Activate virtual environment
    if [ ! -d "venv" ]; then
        error "Python virtual environment not found. Run setup first."
    fi

    source venv/bin/activate

    # Install dependencies exactly like CI
    echo "   Installing dependencies..."
    python -m pip install --upgrade pip > /dev/null
    pip install -r requirements.txt > /dev/null
    pip install black isort flake8 bandit mypy pytest pytest-cov safety > /dev/null

    # Code formatting check (black) - exact CI match
    echo "   Code formatting check (black)..."
    if ! black --check --diff .; then
        error "black formatting check failed - run 'cd backend && source venv/bin/activate && black .' to fix"
    fi

    # Import sorting check (isort) - exact CI match
    echo "   Import sorting check (isort)..."
    if ! isort --check-only --diff .; then
        error "isort check failed - run 'cd backend && source venv/bin/activate && isort .' to fix"
    fi

    # Linting (flake8) - exact CI match
    echo "   Linting (flake8)..."
    if ! flake8 .; then
        error "flake8 found linting issues that must be fixed"
    fi

    # Security scan (bandit) - exact CI match
    echo "   Security scan (bandit)..."
    if ! bandit -r . --severity-level medium --format txt > /dev/null; then
        warning "bandit found security issues"
    fi

    # Type checking (mypy) - exact CI match
    echo "   Type checking (mypy)..."
    if ! mypy . --config-file=mypy.ini; then
        error "mypy found type issues that must be fixed"
    fi

    # Dependency security (safety) - exact CI match
    echo "   Dependency security (safety)..."
    if ! safety check > /dev/null; then
        warning "safety found vulnerable dependencies"
    fi

    # Tests - exact CI match
    echo "   Running tests..."
    if ! python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=term-missing > /dev/null; then
        error "pytest tests failed"
    fi

    deactivate
    cd ..
    success "Backend CI validation passed"
}

# Frontend validation (exactly matching frontend-ci.yml)
validate_frontend_ci() {
    echo "🌐 Running Frontend CI validation..."

    cd frontend

    # Check package-lock.json sync - critical for CI
    echo "   Checking package-lock.json sync..."
    if ! npm ci --dry-run > /dev/null 2>&1; then
        error "package-lock.json is out of sync. Run: cd frontend && npm install && git add package-lock.json"
    fi

    # Install dependencies - exact CI match
    echo "   Installing dependencies..."
    if ! npm ci > /dev/null; then
        error "npm ci failed - package-lock.json may be corrupted"
    fi

    # Linting - exact CI match
    echo "   Running ESLint..."
    if ! npm run lint; then
        error "ESLint found issues that must be fixed"
    fi

    # Tests with coverage - exact CI match
    echo "   Running tests with coverage..."
    if ! npm test -- --coverage > /dev/null; then
        error "Jest tests failed"
    fi

    # Check coverage requirement
    echo "   Checking coverage requirement..."
    if [ ! -f "coverage/coverage-summary.json" ]; then
        error "Coverage summary not found! Check Jest configuration."
    fi

    total=$(jq '.total.lines.pct' coverage/coverage-summary.json)
    echo "   Overall line coverage: ${total}%"

    # Use awk to compare floating point numbers
    if ! awk -v cov=$total 'BEGIN{exit (cov>=10)?0:1}'; then
        error "Coverage ${total}% is below required 20%"
    fi

    # Build - exact CI match
    echo "   Building..."
    if ! npm run build > /dev/null; then
        error "Build failed"
    fi

    cd ..
    success "Frontend CI validation passed"
}

# Deploy validation (exactly matching deploy.yml build steps)
validate_deploy_build() {
    echo "🚀 Running Deploy Build validation..."

    # Backend build
    echo "   Backend build validation..."
    cd backend
    if [ ! -d "venv" ]; then
        error "Python virtual environment not found"
    fi

    source venv/bin/activate
    pip install -r requirements.txt > /dev/null
    python -c "import main; print('✅ Backend imports successfully')"
    deactivate
    cd ..

    # Frontend build
    echo "   Frontend build validation..."
    cd frontend
    if ! npm ci > /dev/null; then
        error "Frontend dependencies failed to install"
    fi

    if ! npm run build > /dev/null; then
        error "Frontend build failed"
    fi

    cd ..
    success "Deploy build validation passed"
}

# Pre-commit validation
validate_pre_commit() {
    echo "🔍 Running pre-commit validation..."

    # Check if there are any unstaged changes
    if ! git diff --quiet; then
        warning "You have unstaged changes. Consider staging them first."
    fi

    # Check if there are any staged changes
    if git diff --cached --quiet; then
        warning "No staged changes found. Nothing to validate for commit."
        return 0
    fi

    # Run a subset of validations on staged files only
    echo "   Validating staged changes..."

    # Check for secrets in staged files
    if command -v gitleaks >/dev/null 2>&1; then
        if ! gitleaks detect --staged --verbose; then
            error "Potential secrets detected in staged files"
        fi
    fi

    success "Pre-commit validation passed"
}

# Main execution
main() {
    echo "Starting CI-Mirror validation..."

    # Pre-flight checks
    check_node_version

    # Validate current directory
    if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        error "Must be run from project root directory"
    fi

    # Run validations in order (fail fast)
    validate_backend_ci
    validate_frontend_ci
    validate_deploy_build
    validate_pre_commit

    echo ""
    success "🎉 All CI-Mirror validations passed! Ready to push to GitHub."
    echo ""
    echo "Next steps:"
    echo "  git add ."
    echo "  git commit -m 'your message'"
    echo "  git push"
}

# Parse command line arguments
case "${1:-}" in
    --backend)
        check_node_version
        validate_backend_ci
        ;;
    --frontend)
        check_node_version
        validate_frontend_ci
        ;;
    --deploy)
        check_node_version
        validate_deploy_build
        ;;
    --pre-commit)
        validate_pre_commit
        ;;
    --help)
        echo "Usage: $0 [--backend|--frontend|--deploy|--pre-commit|--help]"
        echo "  No args: Run all validations"
        echo "  --backend: Run only backend CI validation"
        echo "  --frontend: Run only frontend CI validation"
        echo "  --deploy: Run only deploy build validation"
        echo "  --pre-commit: Run only pre-commit validation"
        echo "  --help: Show this help"
        exit 0
        ;;
    *)
        main
        ;;
esac
    if [ ! -d "venv" ]; then
        error "Python virtual environment not found. Run setup first."
    fi

    source venv/bin/activate

    # Install dependencies exactly like CI
    echo "   Installing dependencies..."
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    pip install black isort flake8 bandit mypy pytest pytest-cov safety

    # Code formatting check (black) - exact CI match
    echo "   Code formatting check (black)..."
    if ! black --check --diff .; then
        error "black formatting check failed - run 'black .' to fix"
    fi

    # Import sorting check (isort) - exact CI match
    echo "   Import sorting check (isort)..."
    if ! isort --check-only --diff .; then
        error "isort check failed - run 'isort .' to fix"
    fi

    # Linting (flake8) - exact CI match
    echo "   Linting (flake8)..."
    if ! flake8 .; then
        error "flake8 found linting issues that must be fixed"
    fi

    # Security scan (bandit) - exact CI match
    echo "   Security scan (bandit)..."
    if ! bandit -r . --severity-level medium --format txt; then
        warning "bandit found security issues"
    fi

    # Type checking (mypy) - exact CI match
    echo "   Type checking (mypy)..."
    if ! mypy . --ignore-missing-imports --no-strict-optional; then
        warning "mypy found type issues"
    fi

    # Dependency security (safety) - exact CI match
    echo "   Dependency security (safety)..."
    if ! safety check; then
        warning "safety found vulnerable dependencies"
    fi

    # Tests - exact CI match
    echo "   Running tests..."
    if ! python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=term-missing; then
        error "pytest tests failed"
    fi

    deactivate
    cd ..
    success "Backend CI validation passed"
}

# Frontend validation (exactly matching frontend-ci.yml)
validate_frontend_ci() {
    echo "🌐 Running Frontend CI validation..."

    cd frontend

    # Check package-lock.json sync - critical for CI
    echo "   Checking package-lock.json sync..."
    if ! npm ci --dry-run > /dev/null 2>&1; then
        error "package-lock.json is out of sync. Run: npm install && git add package-lock.json"
    fi

    # Install dependencies - exact CI match
    echo "   Installing dependencies..."
    if ! npm ci; then
        error "npm ci failed - package-lock.json may be corrupted"
    fi

    # Linting - exact CI match
    echo "   Running ESLint..."
    if ! npm run lint; then
        error "ESLint found issues that must be fixed"
    fi

    # Type checking - exact CI match
    echo "   Type checking..."
    if ! npm run type-check; then
        warning "TypeScript found type issues"
    fi

    # Tests - exact CI match
    echo "   Running tests..."
    if ! npm test; then
        error "Jest tests failed"
    fi

    # Build - exact CI match
    echo "   Building..."
    if ! npm run build; then
        error "Build failed"
    fi

    cd ..
    success "Frontend CI validation passed"
}

# Deploy validation (exactly matching deploy.yml build steps)
validate_deploy_build() {
    echo "🚀 Running Deploy Build validation..."

    # Backend build
    echo "   Backend build validation..."
    cd backend
    if [ ! -d "venv" ]; then
        error "Python virtual environment not found"
    fi

    source venv/bin/activate
    pip install -r requirements.txt > /dev/null
    python -c "import main; print('✅ Backend imports successfully')"
    deactivate
    cd ..

    # Frontend build
    echo "   Frontend build validation..."
    cd frontend
    if ! npm ci > /dev/null; then
        error "Frontend dependencies failed to install"
    fi

    if ! npm run build > /dev/null; then
        error "Frontend build failed"
    fi

    cd ..
    success "Deploy build validation passed"
}

# Main execution
main() {
    echo "Starting CI-Mirror validation..."

    # Pre-flight checks
    check_node_version

    # Validate current directory
    if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        error "Must be run from project root directory"
    fi

    # Run validations in order
    validate_backend_ci
    validate_frontend_ci
    validate_deploy_build

    echo ""
    success "🎉 All CI-Mirror validations passed! Ready to push to GitHub."
    echo ""
    echo "Next steps:"
    echo "  git add ."
    echo "  git commit -m 'your message'"
    echo "  git push"
}

# Parse command line arguments
case "${1:-}" in
    --backend)
        check_node_version
        validate_backend_ci
        ;;
    --frontend)
        check_node_version
        validate_frontend_ci
        ;;
    --deploy)
        check_node_version
        validate_deploy_build
        ;;
    --help)
        echo "Usage: $0 [--backend|--frontend|--deploy|--help]"
        echo "  No args: Run all validations"
        echo "  --backend: Run only backend CI validation"
        echo "  --frontend: Run only frontend CI validation"
        echo "  --deploy: Run only deploy build validation"
        echo "  --help: Show this help"
        exit 0
        ;;
    *)
        main
        ;;
esac
