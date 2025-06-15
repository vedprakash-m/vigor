#!/bin/bash
# Optimized Comprehensive Validation Script for Vigor Project
# Thorough validation but optimized for speed (runs in parallel where possible)

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VALIDATION_ERRORS=0
TEMP_DIR="/tmp/vigor-validation-$(date +%s)"
mkdir -p "$TEMP_DIR"

report_error() {
    echo -e "${RED}❌ $1${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

report_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

report_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

echo "🚀 Optimized comprehensive validation for Vigor project..."
echo "========================================================="

# Run multiple validations in parallel using background processes
run_parallel_validations() {
    # 1. Gitleaks validation (background)
    {
        if [ -f ".gitleaks.toml" ] || [ -f ".github/gitleaks.toml" ]; then
            if command -v gitleaks &> /dev/null; then
                # Run gitleaks with excluded paths for speed
                if gitleaks detect --config .github/gitleaks.toml --no-git --log-level error \
                   --exclude-path=".venv/**" \
                   --exclude-path="node_modules/**" \
                   --exclude-path="**/__pycache__/**" \
                   --exclude-path="coverage/**" \
                   --exclude-path="htmlcov/**" \
                   --exclude-path="e2e-results/**" \
                   --exclude-path=".pytest_cache/**" \
                   >/dev/null 2>&1; then
                    echo "GITLEAKS_OK" > "$TEMP_DIR/gitleaks_result"
                else
                    echo "GITLEAKS_FAIL" > "$TEMP_DIR/gitleaks_result"
                fi
            else
                echo "GITLEAKS_SKIP" > "$TEMP_DIR/gitleaks_result"
            fi
        else
            echo "GITLEAKS_MISSING" > "$TEMP_DIR/gitleaks_result"
        fi
    } &

    # 2. Python syntax validation (background)
    {
        PYTHON_ERRORS=0
        if command -v python3 &> /dev/null; then
            # Use find with -exec for efficiency
            while IFS= read -r -d '' file; do
                if ! python3 -m py_compile "$file" 2>/dev/null; then
                    PYTHON_ERRORS=$((PYTHON_ERRORS + 1))
                    echo "SYNTAX_ERROR: $file" >> "$TEMP_DIR/python_errors"
                fi
            done < <(find backend -name "*.py" -type f -print0 2>/dev/null)
        fi
        echo "PYTHON_ERRORS:$PYTHON_ERRORS" > "$TEMP_DIR/python_result"
    } &

    # 3. Frontend validation (background)
    {
        FRONTEND_RESULT="OK"
        if [ -f "frontend/package.json" ]; then
            if ! python3 -m json.tool frontend/package.json >/dev/null 2>&1; then
                FRONTEND_RESULT="INVALID_JSON"
            elif ! grep -q "\"react\"" frontend/package.json; then
                FRONTEND_RESULT="MISSING_REACT"
            fi
        else
            FRONTEND_RESULT="MISSING_PACKAGE_JSON"
        fi
        echo "FRONTEND:$FRONTEND_RESULT" > "$TEMP_DIR/frontend_result"
    } &

    # 4. Infrastructure validation (background)
    {
        INFRA_RESULT="OK"
        INFRA_WARNINGS=""

        # Check for staging references
        if grep -r "staging" infrastructure/bicep/ --include="*.bicep" --include="*.json" 2>/dev/null | grep -v "stagingEnvironmentPolicy.*Disabled" | grep -q staging; then
            INFRA_WARNINGS="$INFRA_WARNINGS STAGING_REFS"
        fi

        # Check for old multi-region deployments
        if ls infrastructure/bicep/deploy-west-us-2.sh infrastructure/bicep/parameters-westus2.bicepparam 2>/dev/null; then
            INFRA_WARNINGS="$INFRA_WARNINGS OLD_MULTI_REGION"
        fi

        echo "INFRA:$INFRA_RESULT:$INFRA_WARNINGS" > "$TEMP_DIR/infra_result"
    } &

    # 5. Workflow validation (background)
    {
        WORKFLOW_RESULT="OK"
        WORKFLOW_WARNINGS=""

        # Check GitHub Actions workflows
        for workflow in .github/workflows/*.yml; do
            if [ -f "$workflow" ]; then
                # Quick YAML syntax check
                if ! python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
                    WORKFLOW_RESULT="YAML_ERROR"
                    break
                fi

                # Check for staging references
                if grep -q "staging" "$workflow"; then
                    WORKFLOW_WARNINGS="$WORKFLOW_WARNINGS STAGING_REFS"
                fi
            fi
        done

        echo "WORKFLOW:$WORKFLOW_RESULT:$WORKFLOW_WARNINGS" > "$TEMP_DIR/workflow_result"
    } &

    # Wait for all background jobs
    wait
}

# Main validation execution
echo "🔄 Running parallel validations..."
run_parallel_validations

# Process results
echo "📊 Processing validation results..."

# 1. Gitleaks results
if [ -f "$TEMP_DIR/gitleaks_result" ]; then
    GITLEAKS_RESULT=$(cat "$TEMP_DIR/gitleaks_result")
    case "$GITLEAKS_RESULT" in
        "GITLEAKS_OK")
            report_success "Gitleaks validation passed"
            ;;
        "GITLEAKS_FAIL")
            report_error "Gitleaks detected potential secrets"
            ;;
        "GITLEAKS_SKIP")
            report_warning "Gitleaks not installed - skipping secret detection"
            ;;
        "GITLEAKS_MISSING")
            report_warning "Gitleaks configuration file missing"
            ;;
    esac
fi

# 2. Python results
if [ -f "$TEMP_DIR/python_result" ]; then
    PYTHON_RESULT=$(cat "$TEMP_DIR/python_result")
    PYTHON_ERRORS=$(echo "$PYTHON_RESULT" | cut -d: -f2)
    if [ "$PYTHON_ERRORS" -eq 0 ]; then
        report_success "Python syntax validation passed"
    else
        report_error "Python syntax errors found in $PYTHON_ERRORS files"
        if [ -f "$TEMP_DIR/python_errors" ]; then
            cat "$TEMP_DIR/python_errors" | head -5
        fi
    fi
fi

# 3. Frontend results
if [ -f "$TEMP_DIR/frontend_result" ]; then
    FRONTEND_RESULT=$(cat "$TEMP_DIR/frontend_result" | cut -d: -f2)
    case "$FRONTEND_RESULT" in
        "OK")
            report_success "Frontend validation passed"
            ;;
        "INVALID_JSON")
            report_error "Frontend package.json has invalid JSON syntax"
            ;;
        "MISSING_REACT")
            report_error "Frontend missing React dependency"
            ;;
        "MISSING_PACKAGE_JSON")
            report_error "Frontend package.json missing"
            ;;
    esac
fi

# 4. Infrastructure results
if [ -f "$TEMP_DIR/infra_result" ]; then
    INFRA_DATA=$(cat "$TEMP_DIR/infra_result")
    INFRA_RESULT=$(echo "$INFRA_DATA" | cut -d: -f2)
    INFRA_WARNINGS=$(echo "$INFRA_DATA" | cut -d: -f3)

    if [ "$INFRA_RESULT" = "OK" ]; then
        report_success "Infrastructure validation passed"
    fi

    if echo "$INFRA_WARNINGS" | grep -q "STAGING_REFS"; then
        report_warning "Infrastructure still contains staging environment references"
    fi

    if echo "$INFRA_WARNINGS" | grep -q "OLD_MULTI_REGION"; then
        report_warning "Old multi-region deployment files found - consider removing"
    fi
fi

# 5. Workflow results
if [ -f "$TEMP_DIR/workflow_result" ]; then
    WORKFLOW_DATA=$(cat "$TEMP_DIR/workflow_result")
    WORKFLOW_RESULT=$(echo "$WORKFLOW_DATA" | cut -d: -f2)
    WORKFLOW_WARNINGS=$(echo "$WORKFLOW_DATA" | cut -d: -f3)

    case "$WORKFLOW_RESULT" in
        "OK")
            report_success "GitHub Actions workflows validation passed"
            ;;
        "YAML_ERROR")
            report_error "GitHub Actions workflow has YAML syntax errors"
            ;;
    esac

    if echo "$WORKFLOW_WARNINGS" | grep -q "STAGING_REFS"; then
        report_warning "GitHub Actions workflows still reference staging environment"
    fi
fi

# Quick health check validation (static only)
echo "🏥 Quick health check validation..."
if [ -f "scripts/health-check.sh" ]; then
    # Check for obvious issues
    if grep -q "undefined\|localhost:3001" scripts/health-check.sh; then
        report_error "Health check script has undefined or hardcoded endpoints"
    else
        report_success "Health check script validation passed"
    fi
else
    report_error "Health check script missing"
fi

# Git status check
echo "📋 Git status check..."
if [ -n "$(git status --porcelain)" ]; then
    report_warning "Working directory has uncommitted changes"
else
    report_success "Working directory is clean"
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Final summary
echo ""
echo "🎯 Validation Summary"
echo "===================="
if [ $VALIDATION_ERRORS -eq 0 ]; then
    report_success "Optimized validation completed successfully!"
    report_info "Ready for CI/CD deployment"
    exit 0
else
    report_error "Validation failed with $VALIDATION_ERRORS error(s)"
    report_info "Fix these issues before pushing to CI/CD"
    exit 1
fi
