#!/bin/bash

# Comprehensive validation script for GitHub Actions workflows
# Checks for:
# 1. YAML document start markers (---)
# 2. Permissions blocks
# 3. Deprecated actions

echo "===== GitHub Actions Workflow Validation ====="

# Directory containing workflow files
WORKFLOWS_DIR=".github/workflows"
BACKEND_WORKFLOWS_DIR="backend/.github/workflows"
RESULT_FILE="/tmp/workflow_validation_results.txt"

# Create or clear result file
echo "" > $RESULT_FILE

validate_workflow() {
    local file=$1
    local issues_found=0

    echo -e "\nValidating $file..."

    # 1. Check for YAML document start marker
    if ! grep -q '^---' "$file"; then
        echo "  ❌ Missing YAML document start marker (---)" | tee -a $RESULT_FILE
        issues_found=1
    else
        echo "  ✅ Has YAML document start marker" | tee -a $RESULT_FILE
    fi

    # 2. Check for permissions block
    if ! grep -q '^permissions:' "$file"; then
        echo "  ❌ Missing permissions block" | tee -a $RESULT_FILE
        issues_found=1
    else
        echo "  ✅ Has permissions block" | tee -a $RESULT_FILE
    fi

    # 3. Check for deprecated actions
    if grep -q "actions/setup-node@v1" "$file" || grep -q "actions/setup-node@v2" "$file"; then
        echo "  ❌ Using deprecated Node.js setup action" | tee -a $RESULT_FILE
        issues_found=1
    fi

    if grep -q "actions/setup-python@v1" "$file" || grep -q "actions/setup-python@v2" "$file" || grep -q "actions/setup-python@v3" "$file"; then
        echo "  ❌ Using deprecated Python setup action" | tee -a $RESULT_FILE
        issues_found=1
    fi

    if grep -q "actions/checkout@v1" "$file" || grep -q "actions/checkout@v2" "$file" || grep -q "actions/checkout@v3" "$file"; then
        echo "  ❌ Using deprecated checkout action" | tee -a $RESULT_FILE
        issues_found=1
    fi

    # Check for API URL patterns and warn about rate limits
    if grep -q "api.github.com" "$file"; then
        echo "  ⚠️ Using GitHub API directly - ensure rate limits are handled" | tee -a $RESULT_FILE
    fi

    # Success if no issues found
    if [ $issues_found -eq 0 ]; then
        echo "  ✅ No major issues found" | tee -a $RESULT_FILE
    fi

    return $issues_found
}

# Validate all workflows in main workflows directory
echo "Checking main workflows directory..."
if [ -d "$WORKFLOWS_DIR" ]; then
    FAILED_WORKFLOWS=0
    for file in "$WORKFLOWS_DIR"/*.yml; do
        if [ -f "$file" ]; then
            validate_workflow "$file"
            FAILED_WORKFLOWS=$((FAILED_WORKFLOWS + $?))
        fi
    done

    if [ $FAILED_WORKFLOWS -gt 0 ]; then
        echo -e "\n❌ $FAILED_WORKFLOWS workflows have issues that need to be fixed"
    else
        echo -e "\n✅ All workflows in main directory pass validation"
    fi
else
    echo "❌ Main workflows directory not found: $WORKFLOWS_DIR"
fi

# Validate all workflows in backend workflows directory, if it exists
if [ -d "$BACKEND_WORKFLOWS_DIR" ]; then
    echo -e "\nChecking backend workflows directory..."
    FAILED_WORKFLOWS=0
    for file in "$BACKEND_WORKFLOWS_DIR"/*.yml; do
        if [ -f "$file" ]; then
            validate_workflow "$file"
            FAILED_WORKFLOWS=$((FAILED_WORKFLOWS + $?))
        fi
    done

    if [ $FAILED_WORKFLOWS -gt 0 ]; then
        echo -e "\n❌ $FAILED_WORKFLOWS workflows in backend directory have issues that need to be fixed"
    else
        echo -e "\n✅ All workflows in backend directory pass validation"
    fi
fi

echo -e "\nValidation complete. Detailed results saved to $RESULT_FILE"
