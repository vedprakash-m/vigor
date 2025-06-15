#!/bin/bash
# Quick validation test script

echo "🔍 Running quick validation test..."

# Test 1: Check if backend CI workflow exists in correct location
if [ -f ".github/workflows/backend-ci.yml" ]; then
    echo "✅ Backend CI workflow found in correct location"
else
    echo "❌ Backend CI workflow missing from .github/workflows/"
    exit 1
fi

# Test 2: Check for deprecated upload-artifact actions
if grep -r "upload-artifact@v3" .github/workflows/; then
    echo "❌ Found deprecated upload-artifact@v3"
    exit 1
else
    echo "✅ No deprecated upload-artifact actions found"
fi

# Test 3: Check for missing permissions blocks
missing_permissions=0
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        if ! grep -q "permissions:" "$workflow"; then
            echo "❌ $workflow missing permissions block"
            missing_permissions=$((missing_permissions + 1))
        fi
    fi
done

if [ $missing_permissions -eq 0 ]; then
    echo "✅ All workflows have permissions blocks"
else
    echo "❌ $missing_permissions workflows missing permissions blocks"
    exit 1
fi

# Test 4: Check for YAML document start markers
missing_yaml_start=0
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        if ! head -1 "$workflow" | grep -q "^---"; then
            echo "❌ $workflow missing YAML document start marker"
            missing_yaml_start=$((missing_yaml_start + 1))
        fi
    fi
done

if [ $missing_yaml_start -eq 0 ]; then
    echo "✅ All workflows have YAML document start markers"
else
    echo "❌ $missing_yaml_start workflows missing YAML document start markers"
    exit 1
fi

echo "🎉 Quick validation passed!"
