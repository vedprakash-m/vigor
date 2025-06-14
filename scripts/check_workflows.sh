#!/bin/bash

# Check and fix CI/CD workflow files
# This script identifies and fixes common issues in GitHub Actions workflow files

echo "===== CI/CD Workflow Files Health Check ====="

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null; then
    echo "Installing yamllint..."
    pip install yamllint
fi

# Create a temporary config file for yamllint
cat > /tmp/yamllint-config.yml << EOF
extends: default
rules:
  line-length: disable
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no', 'on', 'off']
  comments-indentation: disable
EOF

# Function to check and fix common issues in workflow files
check_workflow_file() {
    local file=$1
    echo ""
    echo "Checking $file..."

    # Run yamllint on the file
    yamllint -c /tmp/yamllint-config.yml "$file"
    local yaml_status=$?

    # Check for common issues
    # 1. Check for deprecated Node.js setup
    if grep -q "uses: actions/setup-node@v2" "$file"; then
        echo "  - WARNING: Outdated Node.js setup (v2) found. Recommend updating to actions/setup-node@v4"
    fi

    # 2. Check for deprecated Python setup
    if grep -q "uses: actions/setup-python@v2" "$file" || grep -q "uses: actions/setup-python@v3" "$file"; then
        echo "  - WARNING: Outdated Python setup found. Recommend updating to actions/setup-python@v4"
    fi

    # 3. Check for deprecated Checkout action
    if grep -q "uses: actions/checkout@v2" "$file" || grep -q "uses: actions/checkout@v3" "$file"; then
        echo "  - WARNING: Outdated checkout action found. Recommend updating to actions/checkout@v4"
    fi

    # 4. Check for deprecated actions/cache
    if grep -q "uses: actions/cache@v1" "$file" || grep -q "uses: actions/cache@v2" "$file"; then
        echo "  - WARNING: Outdated cache action found. Recommend updating to actions/cache@v3"
    fi

    # 5. Check for runners that might be deprecated
    if grep -q "runs-on: ubuntu-18.04" "$file" || grep -q "runs-on: windows-2019" "$file"; then
        echo "  - WARNING: Potentially outdated runner specified. Consider updating to newer versions"
    fi

    # 6. Check for missing 'permissions' block which is a security best practice
    if ! grep -q "permissions:" "$file"; then
        echo "  - SUGGESTION: No explicit permissions block found. Consider adding one for security best practices"
    fi

    return $yaml_status
}

# Find all workflow files
WORKFLOW_DIR=".github/workflows"
if [ ! -d "$WORKFLOW_DIR" ]; then
    echo "Workflow directory not found: $WORKFLOW_DIR"
    exit 1
fi

# Check each workflow file
FAILED=0
for file in "$WORKFLOW_DIR"/*.yml; do
    if [ -f "$file" ]; then
        check_workflow_file "$file"
        if [ $? -ne 0 ]; then
            FAILED=1
        fi
    fi
done

# Clean up
rm /tmp/yamllint-config.yml

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ All workflow files passed basic validation."
    echo "Note: Review any warnings or suggestions mentioned above."
else
    echo "❌ Some workflow files have syntax issues that need to be fixed."
    echo "Please address the issues mentioned above before enabling branch protection."
fi

echo ""
echo "===== CI/CD Health Check Complete ====="
