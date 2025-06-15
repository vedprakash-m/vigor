#!/bin/bash
# Fast Local Validation Script for Vigor Project
# Focus on the most critical checks that prevent CI/CD failures

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "🚀 Fast validation for Vigor project..."
echo "======================================"

# 1. Check critical files exist (fast file checks)
echo "📁 Checking critical files..."
CRITICAL_FILES=(
    ".github/workflows/deploy.yml"
    "backend/main.py"
    "frontend/package.json"
    "infrastructure/bicep/main.bicep"
    "scripts/health-check.sh"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        report_error "Missing critical file: $file"
    fi
done

# 2. Quick syntax validation (parallel where possible)
echo "🔍 Quick syntax validation..."

# Check Python syntax (fast)
if command -v python3 &> /dev/null; then
    if ! python3 -m py_compile backend/main.py 2>/dev/null; then
        report_error "Python syntax error in backend/main.py"
    fi
fi

# Check JSON files (fast)
for json_file in frontend/package.json; do
    if [ -f "$json_file" ] && ! python3 -m json.tool "$json_file" >/dev/null 2>&1; then
        report_error "Invalid JSON in $json_file"
    fi
done

# Check YAML syntax (GitHub Actions)
for yaml_file in .github/workflows/*.yml; do
    if [ -f "$yaml_file" ]; then
        # Basic YAML check - just ensure it's parseable
        if ! python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            report_error "Invalid YAML syntax in $yaml_file"
        fi
    fi
done

# 3. Critical configuration checks (very fast)
echo "⚙️ Configuration validation..."

# Check if deployment workflow targets the right environment
if grep -q "staging" .github/workflows/deploy.yml 2>/dev/null; then
    report_warning "Deployment workflow still references staging environment"
fi

# Check health check script has valid endpoints
if [ -f "scripts/health-check.sh" ]; then
    # Quick check for obviously broken endpoints
    if grep -q "undefined\|localhost:3001" scripts/health-check.sh; then
        report_error "Health check script has undefined or hardcoded localhost endpoints"
    fi
fi

# 4. Infrastructure validation (basic checks only)
echo "🏗️ Infrastructure validation..."

# Check Bicep template can at least be read
if [ -f "infrastructure/bicep/main.bicep" ]; then
    # Just check for basic syntax issues
    if grep -q "stagingEnvironmentPolicy.*Enabled" infrastructure/bicep/main.bicep infrastructure/bicep/*.bicep 2>/dev/null; then
        report_warning "Infrastructure still has staging environment enabled"
    fi
fi

# 5. Quick dependency check
echo "📦 Dependency validation..."

# Check if package.json has critical dependencies
if [ -f "frontend/package.json" ]; then
    if ! grep -q "\"react\"" frontend/package.json; then
        report_error "Frontend missing React dependency"
    fi
fi

# Check if requirements.txt exists for Python
if [ ! -f "backend/requirements.txt" ]; then
    report_error "Backend missing requirements.txt"
fi

# 6. Git status check (very fast)
echo "📋 Git status check..."
if [ -n "$(git status --porcelain)" ]; then
    report_warning "Working directory has uncommitted changes"
fi

# Final summary
echo ""
if [ $VALIDATION_ERRORS -eq 0 ]; then
    report_success "Fast validation completed successfully! Ready for CI/CD."
    echo "💡 Tip: This validation takes ~5-10 seconds vs ~2-3 minutes for full validation"
    exit 0
else
    report_error "Validation failed with $VALIDATION_ERRORS error(s)"
    echo "🔧 Fix these issues before pushing to CI/CD"
    exit 1
fi
