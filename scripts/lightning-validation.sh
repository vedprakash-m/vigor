#!/bin/bash
# Lightning-Fast Local Validation Script for Vigor Project
# Optimized for developer productivity - skips slow checks that CI/CD handles better

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VALIDATION_ERRORS=0

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

echo "⚡ Lightning-fast validation for Vigor project..."
echo "================================================"
start_time=$(date +%s)

# 1. Critical file existence (instant)
critical_files=(
    ".github/workflows/deploy.yml"
    "backend/main.py"
    "frontend/package.json"
    "infrastructure/bicep/main.bicep"
    "scripts/health-check.sh"
    "backend/requirements.txt"
)

missing_files=()
for file in "${critical_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    report_success "All critical files present"
else
    for file in "${missing_files[@]}"; do
        report_error "Missing critical file: $file"
    done
fi

# 2. Python syntax check (fast, parallel)
echo "🐍 Checking Python syntax..."
python_errors=0
if command -v python3 &> /dev/null; then
    # Check main files only (not entire codebase)
    main_python_files=(
        "backend/main.py"
        "backend/api/routes/users.py"
        "backend/api/routes/workouts.py"
        "backend/core/config.py"
    )

    for file in "${main_python_files[@]}"; do
        if [ -f "$file" ] && ! python3 -m py_compile "$file" 2>/dev/null; then
            report_error "Python syntax error in $file"
            python_errors=$((python_errors + 1))
        fi
    done

    if [ $python_errors -eq 0 ]; then
        report_success "Python syntax validation passed"
    fi
else
    report_warning "Python3 not available - skipping syntax check"
fi

# 3. JSON validation (instant)
echo "📋 Checking JSON files..."
json_files=("frontend/package.json")
json_errors=0

for file in "${json_files[@]}"; do
    if [ -f "$file" ]; then
        if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            report_error "Invalid JSON in $file"
            json_errors=$((json_errors + 1))
        fi
    fi
done

if [ $json_errors -eq 0 ]; then
    report_success "JSON validation passed"
fi

# 4. Quick configuration checks (instant)
echo "⚙️ Checking configuration..."

# Check for staging references in key files
staging_issues=0
key_files=(".github/workflows/deploy.yml" "infrastructure/bicep/main.bicep")

for file in "${key_files[@]}"; do
    if [ -f "$file" ] && grep -q "staging" "$file" 2>/dev/null; then
        report_warning "$file still contains staging references"
        staging_issues=$((staging_issues + 1))
    fi
done

if [ $staging_issues -eq 0 ]; then
    report_success "No staging environment references found"
fi

# Check Azure OIDC permissions in workflows
oidc_issues=0
azure_workflows=(".github/workflows/deploy.yml")

for file in "${azure_workflows[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "azure/login@" "$file" && ! grep -q "id-token: write" "$file"; then
            report_error "$file uses Azure login but missing 'id-token: write' permission"
            oidc_issues=$((oidc_issues + 1))
        fi
    fi
done

if [ $oidc_issues -eq 0 ] && [ -f ".github/workflows/deploy.yml" ]; then
    report_success "Azure OIDC authentication properly configured"
fi

# Check documentation links in README
doc_link_issues=0
readme_doc_links=(
    "docs/getting-started.md"
    "docs/deployment.md"
    "docs/architecture.md"
    "docs/CONTRIBUTING.md"
)

for link in "${readme_doc_links[@]}"; do
    if [ -f "README.md" ] && grep -q "$link" README.md && [ ! -f "$link" ]; then
        report_error "README.md links to missing file: $link"
        doc_link_issues=$((doc_link_issues + 1))
    fi
done

if [ $doc_link_issues -eq 0 ]; then
    report_success "Documentation links verified"
fi

# 5. Health check script validation (instant)
echo "🏥 Checking health check script..."
if [ -f "scripts/health-check.sh" ]; then
    if grep -q "undefined\|localhost:3001\|REPLACE_ME" scripts/health-check.sh 2>/dev/null; then
        report_error "Health check script has placeholder or invalid endpoints"
    else
        report_success "Health check script looks good"
    fi
else
    report_error "Health check script missing"
fi

# 6. Dependencies check (instant)
echo "📦 Checking dependencies..."
deps_ok=true

# Check React in frontend
if [ -f "frontend/package.json" ] && ! grep -q "\"react\"" frontend/package.json; then
    report_error "Frontend missing React dependency"
    deps_ok=false
fi

# Check FastAPI in backend
if [ -f "backend/requirements.txt" ] && ! grep -q "fastapi" backend/requirements.txt; then
    report_error "Backend missing FastAPI dependency"
    deps_ok=false
fi

if $deps_ok; then
    report_success "Key dependencies verified"
fi

# 7. Git status (instant)
echo "📋 Checking git status..."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    report_info "Working directory has uncommitted changes (this is often normal during development)"
else
    report_success "Working directory is clean"
fi

# Final summary
end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "🎯 Validation Summary"
echo "===================="
echo "⏱️ Completed in ${duration} seconds"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    report_success "Lightning-fast validation passed! 🚀"
    report_info "Your code is ready for CI/CD deployment"
    echo ""
    echo "💡 Note: This fast validation skips some checks that GitHub Actions handles better:"
    echo "   - Secret scanning (gitleaks) - GitHub Advanced Security does this"
    echo "   - Full test suite - CI/CD runs comprehensive tests"
    echo "   - Infrastructure deployment test - CI/CD validates this"
    echo ""
    exit 0
else
    report_error "Validation failed with $VALIDATION_ERRORS critical issue(s)"
    echo ""
    echo "🔧 Fix these issues before pushing to GitHub"
    echo "💡 For comprehensive validation, use: ./scripts/optimized-validation.sh"
    echo ""
    exit 1
fi
