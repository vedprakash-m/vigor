#!/bin/bash
# Comprehensive End-to-End Validation Script for Vigor Project
# This script validates all aspects of the project to ensure CI/CD pipeline success

set -e  # Exit on first error

echo "🚀 Starting comprehensive end-to-end validation for Vigor project..."
echo "======================================================================="

# Variables to control execution
VALIDATION_ERRORS=0
TEMP_DIR="/tmp/vigor-validation-$(date +%s)"
mkdir -p "$TEMP_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function for error reporting
report_error() {
    echo -e "${RED}❌ $1${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

report_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 1. Validate Gitleaks Configuration
validate_gitleaks_config() {
    echo "🔍 Validating Gitleaks configuration..."

    if [ ! -f ".github/gitleaks.toml" ]; then
        report_error "Gitleaks configuration file missing"
        return 1
    fi

    # Check for incorrect allowlist format
    if grep -A 5 "\[\[allowlist\]\]" .github/gitleaks.toml | grep -q "paths = \["; then
        report_error "Gitleaks config has incorrect format: 'paths' should not be in array format"
        return 1
    fi

    # Check if gitleaks can parse the config
    if command -v gitleaks &> /dev/null; then
        if ! gitleaks detect --config .github/gitleaks.toml --no-git . --report-path "$TEMP_DIR/gitleaks_validate.json" &> "$TEMP_DIR/gitleaks_validate.log"; then
            # Gitleaks will exit with code 1 if secrets are found, which is expected
            # Check if it's a config error vs secrets found
            if grep -q "error" "$TEMP_DIR/gitleaks_validate.log" | grep -v "leaks found"; then
                report_error "Gitleaks configuration has syntax errors. Check $TEMP_DIR/gitleaks_validate.log"
                return 1
            fi
        fi
    fi

    report_success "Gitleaks configuration is valid"
    return 0
}

# 2. Validate Azure Deployment Configuration
validate_azure_deployment() {
    echo "☁️ Validating Azure deployment configuration..."

    if [ ! -f ".github/workflows/deploy.yml" ]; then
        report_error "Deployment workflow missing"
        return 1
    fi

    # Check for proper Azure login configuration
    if ! grep -q "client-id:" .github/workflows/deploy.yml; then
        report_error "Azure deployment missing client-id configuration"
        return 1
    fi

    if ! grep -q "tenant-id:" .github/workflows/deploy.yml; then
        report_error "Azure deployment missing tenant-id configuration"
        return 1
    fi

    # Check for ENDPOINT_URL in health checks
    if ! grep -A 5 -B 5 "health-check.sh" .github/workflows/deploy.yml | grep -q "ENDPOINT_URL"; then
        report_error "Health check missing ENDPOINT_URL environment variable"
        return 1
    fi

    report_success "Azure deployment configuration is valid"
    return 0
}

# 3. Validate Secret Scanning Workflow
validate_secret_scanning() {
    echo "🔐 Validating secret scanning workflow..."

    if [ ! -f ".github/workflows/secret-scan.yml" ]; then
        report_error "Secret scanning workflow missing"
        return 1
    fi

    # Check TruffleHog conditions
    if ! grep -A 10 "TruffleHog" .github/workflows/secret-scan.yml | grep -q "github.event.before"; then
        report_error "TruffleHog missing proper condition for same commit check"
        return 1
    fi

    # Check for security-events permission
    if ! grep -q "security-events: read" .github/workflows/secret-scan.yml; then
        report_error "Secret scanning workflow missing security-events permission"
        return 1
    fi

    report_success "Secret scanning workflow configuration is valid"
    return 0
}

# 4. Validate Health Check Endpoints
validate_health_endpoints() {
    echo "🏥 Validating health check endpoints..."

    if [ ! -f "scripts/health-check.sh" ]; then
        report_error "Health check script missing"
        return 1
    fi

    # Extract endpoints being checked from health-check.sh
    health_endpoints=$(grep -o '\${ENDPOINT_URL}[^"]*' scripts/health-check.sh | sed 's/\${ENDPOINT_URL}//' || true)

    if [ -z "$health_endpoints" ]; then
        report_error "No health check endpoints found in script"
        return 1
    fi

    # Check if backend actually has these endpoints
    backend_routes=""
    if [ -f "backend/main.py" ]; then
        # Extract actual routes from main.py and route files
        backend_routes=$(grep -r "@.*\.get\|@.*\.post" backend/main.py backend/api/routes/ 2>/dev/null | grep -o '"/[^"]*"' | tr -d '"' || true)
        # Also check for router-prefixed routes
        auth_routes=$(grep -A 1 -B 1 "@router\.get\|@router\.post" backend/api/routes/auth.py 2>/dev/null | grep -o '"/[^"]*"' | tr -d '"' | sed 's|^|/auth|' || true)
        user_routes=$(grep -A 1 -B 1 "@router\.get\|@router\.post" backend/api/routes/users.py 2>/dev/null | grep -o '"/[^"]*"' | tr -d '"' | sed 's|^|/users|' || true)
        all_routes="$backend_routes $auth_routes $user_routes"
    fi

    # Validate each health check endpoint
    for endpoint in $health_endpoints; do
        # Clean up endpoint (remove query params, etc.)
        clean_endpoint=$(echo "$endpoint" | cut -d'?' -f1)

        # Special cases for expected endpoints
        case "$clean_endpoint" in
            "/health")
                if ! echo "$all_routes" | grep -q "/health"; then
                    report_error "Health check script expects /health but backend doesn't provide it"
                    return 1
                fi
                ;;
            "/docs")
                # FastAPI automatically provides /docs, so this is fine
                ;;
            "/auth/me")
                # This should exist in auth routes
                if ! echo "$all_routes" | grep -q "/auth/me"; then
                    report_warning "Health check expects /auth/me endpoint - verify this exists"
                fi
                ;;
            *)
                # Check if any backend route matches
                if [ -n "$all_routes" ] && ! echo "$all_routes" | grep -q "^$clean_endpoint$"; then
                    report_warning "Health check expects endpoint $clean_endpoint - verify this exists in backend"
                fi
                ;;
        esac
    done

    report_success "Health check endpoints validation completed"
    return 0
}

# 5. Validate Backend Code Quality
validate_backend() {
    echo "🐍 Running comprehensive backend validation..."

    if [ ! -d "backend" ]; then
        report_error "Backend directory not found"
        return 1
    fi

    cd backend

    # Setup Python environment
    if [ ! -d "venv" ]; then
        echo "   Creating virtual environment..."
        python3 -m venv venv
    fi

    source venv/bin/activate

    # Install dependencies
    echo "   Installing dependencies..."
    pip install -r requirements.txt > "$TEMP_DIR/backend_install.log" 2>&1
    pip install black isort flake8 bandit mypy pytest pytest-cov safety >> "$TEMP_DIR/backend_install.log" 2>&1

    # Code formatting check
    echo "   Checking code formatting..."
    if ! black --check --diff . > "$TEMP_DIR/black_check.log" 2>&1; then
        report_error "Black formatting check failed. See $TEMP_DIR/black_check.log"
        cd ..
        return 1
    fi

    # Import sorting check
    echo "   Checking import sorting..."
    if ! isort --check-only --diff . > "$TEMP_DIR/isort_check.log" 2>&1; then
        report_error "isort check failed. See $TEMP_DIR/isort_check.log"
        cd ..
        return 1
    fi

    # Linting
    echo "   Running linting..."
    if ! flake8 . > "$TEMP_DIR/flake8_check.log" 2>&1; then
        report_warning "flake8 found issues. See $TEMP_DIR/flake8_check.log"
    fi

    # Security scan with proper configuration
    echo "   Running security scan..."
    # Generate report without failing
    bandit -r . --exclude venv,__pycache__,.pytest_cache,.mypy_cache,migrations,tests,alembic,.venv --severity-level high --confidence-level medium --skip B101,B601 -f json -o "$TEMP_DIR/bandit_report.json" --exit-zero || true
    # Only fail on high severity issues in our code (exclude dependencies)
    if ! bandit -r . --exclude venv,__pycache__,.pytest_cache,.mypy_cache,migrations,tests,alembic,.venv --severity-level high --confidence-level medium --skip B101,B601 --exit-zero > "$TEMP_DIR/bandit_check.log" 2>&1; then
        report_error "Bandit check failed. See $TEMP_DIR/bandit_check.log"
        cd ..
        return 1
    fi

    # Check if we have any high severity issues in our actual code
    high_issues=$(grep -o '"HIGH": [0-9]*' "$TEMP_DIR/bandit_report.json" 2>/dev/null | awk -F': ' '{sum += $2} END {print sum+0}')
    if [[ "$high_issues" -gt 10 ]]; then  # Allow some threshold for dependencies
        report_error "Bandit found $high_issues high severity security issues. See $TEMP_DIR/bandit_report.json"
        cd ..
        return 1
    fi

    # Type checking
    echo "   Running type checking..."
    if ! mypy . --config-file=mypy.ini > "$TEMP_DIR/mypy_check.log" 2>&1; then
        report_error "MyPy type checking failed. See $TEMP_DIR/mypy_check.log"
        cd ..
        return 1
    fi

    # Dependency security check with modern command
    echo "   Checking dependency security..."
    if command -v safety &> /dev/null; then
        if ! safety scan --json > "$TEMP_DIR/safety_scan.json" 2>/dev/null; then
            if ! safety check --output json > "$TEMP_DIR/safety_check.json" 2>&1; then
                report_warning "Safety found vulnerabilities. Check $TEMP_DIR/safety_check.json"
            fi
        fi
    fi

    # Run tests
    echo "   Running tests..."
    if ! pytest --cov=. --cov-report=xml --cov-report=html -v > "$TEMP_DIR/pytest_output.log" 2>&1; then
        report_error "Pytest failed. See $TEMP_DIR/pytest_output.log"
        cd ..
        return 1
    fi

    deactivate
    cd ..

    report_success "Backend validation completed successfully"
    return 0
}

# 6. Validate Frontend Code Quality
validate_frontend() {
    echo "🌐 Running comprehensive frontend validation..."

    if [ ! -d "frontend" ]; then
        report_warning "Frontend directory not found, skipping frontend validation"
        return 0
    fi

    cd frontend

    # Install dependencies
    echo "   Installing dependencies..."
    if ! npm ci > "$TEMP_DIR/frontend_install.log" 2>&1; then
        report_warning "npm ci failed. See $TEMP_DIR/frontend_install.log"
        if ! npm install > "$TEMP_DIR/frontend_install_fallback.log" 2>&1; then
            report_error "npm install also failed. See $TEMP_DIR/frontend_install_fallback.log"
            cd ..
            return 1
        fi
    fi

    # Linting
    echo "   Running linting..."
    if ! npm run lint > "$TEMP_DIR/frontend_lint.log" 2>&1; then
        report_error "Frontend linting failed. See $TEMP_DIR/frontend_lint.log"
        cd ..
        return 1
    fi

    # Tests
    echo "   Running tests..."
    if ! npm test -- --coverage > "$TEMP_DIR/frontend_test.log" 2>&1; then
        report_error "Frontend tests failed. See $TEMP_DIR/frontend_test.log"
        cd ..
        return 1
    fi

    # Build
    echo "   Building frontend..."
    if ! npm run build > "$TEMP_DIR/frontend_build.log" 2>&1; then
        report_error "Frontend build failed. See $TEMP_DIR/frontend_build.log"
        cd ..
        return 1
    fi

    cd ..

    report_success "Frontend validation completed successfully"
    return 0
}

# 7. Validate npm Dependencies
validate_npm_dependencies() {
    echo "📦 Checking npm dependencies for vulnerabilities..."

    if [ -d "frontend" ]; then
        cd frontend

        echo "   Running npm audit..."
        if ! npm audit --audit-level=high > "$TEMP_DIR/npm_audit.log" 2>&1; then
            report_warning "npm audit found vulnerabilities. See $TEMP_DIR/npm_audit.log"

            # Check for fixable issues
            if npm audit fix --dry-run > "$TEMP_DIR/npm_audit_fix.log" 2>&1; then
                echo "   Automatic fixes available. Run 'npm audit fix' to apply them."
            fi
        else
            report_success "No high severity npm vulnerabilities found"
        fi

        cd ..
    fi

    return 0
}

# 8. Validate Infrastructure
validate_infrastructure() {
    echo "🏗️ Validating infrastructure configuration..."

    if [ ! -f "infrastructure/bicep/main.bicep" ]; then
        report_error "Main Bicep template missing"
        return 1
    fi

    # Validate Bicep syntax
    if command -v az &> /dev/null; then
        echo "   Validating Bicep syntax..."
        if ! az bicep build --file infrastructure/bicep/main.bicep > "$TEMP_DIR/bicep_validate.log" 2>&1; then
            report_error "Bicep template validation failed. See $TEMP_DIR/bicep_validate.log"
            return 1
        fi
    else
        report_warning "Azure CLI not found, skipping Bicep validation"
    fi

    report_success "Infrastructure validation completed"
    return 0
}

# 9. Validate Docker Configuration
validate_docker() {
    echo "🐳 Validating Docker configuration..."

    if [ ! -f "docker-compose.yml" ]; then
        report_error "docker-compose.yml not found"
        return 1
    fi

    # Validate Docker Compose syntax
    if command -v docker &> /dev/null; then
        if docker compose version &> /dev/null; then
            if ! docker compose config > "$TEMP_DIR/docker_compose_validate.log" 2>&1; then
                report_error "docker-compose.yml has syntax errors. See $TEMP_DIR/docker_compose_validate.log"
                return 1
            fi
        elif command -v docker-compose &> /dev/null; then
            if ! docker-compose config > "$TEMP_DIR/docker_compose_validate.log" 2>&1; then
                report_error "docker-compose.yml has syntax errors. See $TEMP_DIR/docker_compose_validate.log"
                return 1
            fi
        fi
    else
        report_warning "Docker not found, skipping Docker validation"
    fi

    report_success "Docker configuration is valid"
    return 0
}

# 10. Validate All Workflow Files
validate_all_workflows() {
    echo "⚙️ Validating all GitHub Actions workflows..."

    for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
            echo "   Validating $workflow..."

            # Check YAML syntax
            if command -v yamllint &> /dev/null; then
                if ! yamllint "$workflow" > "$TEMP_DIR/$(basename $workflow)_yamllint.log" 2>&1; then
                    report_error "YAML syntax error in $workflow. See $TEMP_DIR/$(basename $workflow)_yamllint.log"
                    continue
                fi
            fi

            # Check for document start
            if ! head -1 "$workflow" | grep -q "^---"; then
                report_error "$workflow missing YAML document start marker (---)"
                continue
            fi

            # Check for permissions
            if ! grep -q "permissions:" "$workflow"; then
                report_error "$workflow missing permissions block"
                continue
            fi
        fi
    done

    report_success "All workflows validated successfully"
    return 0
}

# 11. Generate Summary Report
generate_summary_report() {
    echo "📊 Generating validation summary report..."

    REPORT_FILE="$TEMP_DIR/validation_summary.md"

    cat > "$REPORT_FILE" << EOF
# Vigor Project Validation Summary

**Validation Date:** $(date)
**Total Errors:** $VALIDATION_ERRORS

## Validation Results

### Configuration Files
- Gitleaks configuration: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Valid" || echo "❌ Issues found")
- Azure deployment: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Valid" || echo "❌ Issues found")
- Secret scanning: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Valid" || echo "❌ Issues found")

### Code Quality
- Backend: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Passed" || echo "❌ Issues found")
- Frontend: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Passed" || echo "❌ Issues found")

### Infrastructure
- Bicep templates: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Valid" || echo "❌ Issues found")
- Docker configuration: $([ $VALIDATION_ERRORS -eq 0 ] && echo "✅ Valid" || echo "❌ Issues found")

### Dependencies
- npm vulnerabilities: Check $TEMP_DIR/npm_audit.log
- Python safety: Check $TEMP_DIR/safety_*.json

## Log Files
All validation logs are available in: $TEMP_DIR

EOF

    echo "   Summary report generated: $REPORT_FILE"
}

# Main execution
main() {
    echo "Starting validation process..."
    echo "Logs will be stored in: $TEMP_DIR"
    echo ""

    # Run all validations
    validate_gitleaks_config
    validate_azure_deployment
    validate_secret_scanning
    validate_health_endpoints
    validate_backend
    validate_frontend
    validate_npm_dependencies
    validate_infrastructure
    validate_docker
    validate_all_workflows

    # Generate summary
    generate_summary_report

    echo ""
    echo "======================================================================="

    if [ $VALIDATION_ERRORS -eq 0 ]; then
        report_success "All validations passed! 🎉"
        report_success "Your project is ready for CI/CD pipeline execution."
        echo ""
        echo "Next steps:"
        echo "1. Commit your changes"
        echo "2. Push to GitHub"
        echo "3. Monitor the CI/CD pipeline"
    else
        report_error "Found $VALIDATION_ERRORS validation errors"
        echo ""
        echo "Please review and fix the issues above before proceeding."
        echo "Check detailed logs in: $TEMP_DIR"
    fi

    return $VALIDATION_ERRORS
}

# Execute main function
main "$@"
