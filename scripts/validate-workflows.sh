#!/bin/bash
# This script validates all GitHub Action workflow files in the repository

set -e

echo "🔍 Validating GitHub Action workflow files..."

# Check if actionlint is installed
if ! command -v actionlint &> /dev/null; then
  echo "actionlint not found. Installing..."
  if command -v brew &> /dev/null; then
    brew install actionlint
  else
    echo "Unable to automatically install actionlint. Please install it manually."
    echo "See: https://github.com/rhysd/actionlint#installation"
    exit 1
  fi
fi

# Install yamllint if needed
if ! command -v yamllint &> /dev/null; then
  echo "yamllint not found. Installing..."
  if command -v pip3 &> /dev/null; then
    pip3 install yamllint
  else
    echo "Unable to automatically install yamllint. Please install it manually."
    echo "Run: pip install yamllint"
    exit 1
  fi
fi

echo "📝 Running YAML linting on workflow files..."
yamllint -d relaxed .github/workflows/

echo "📝 Running actionlint on workflow files..."
actionlint .github/workflows/*.yml

# Check for common issues
echo "📝 Checking for common workflow issues..."

ISSUES_FOUND=0

# Check for unpinned actions
echo "Checking for unpinned actions..."
UNPINNED=$(grep -r "uses: " .github/workflows/ | grep -v "@[0-9a-f]\{40\}" | grep -v "uses: ./")
if [ ! -z "$UNPINNED" ]; then
  echo "⚠️ Found actions not pinned to a specific SHA:"
  echo "$UNPINNED"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for missing timeout settings
echo "Checking for missing timeout settings..."
MISSING_TIMEOUT=$(grep -L "timeout-minutes:" .github/workflows/*.yml | wc -l)
if [ $MISSING_TIMEOUT -gt 0 ]; then
  echo "⚠️ Found $(grep -L "timeout-minutes:" .github/workflows/*.yml | wc -l) workflows without timeout-minutes specified"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for potentially leaking secrets
echo "Checking for potential secret leakage..."
POTENTIAL_LEAKS=$(grep -r "secrets\." .github/workflows/ | grep -E "echo|printf|cat")
if [ ! -z "$POTENTIAL_LEAKS" ]; then
  echo "⚠️ Potential secret leakage detected:"
  echo "$POTENTIAL_LEAKS"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check if workflows are reachable
echo "Checking for unreachable workflows..."
for file in .github/workflows/*.yml; do
  if ! grep -q -E "on:|workflow_call:" $file; then
    echo "⚠️ Workflow $file may not have a trigger defined"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  fi
done

# Final report
if [ $ISSUES_FOUND -eq 0 ]; then
  echo "✅ All workflow validation checks passed!"
else
  echo "⚠️ Found $ISSUES_FOUND potential issues to address"
  echo "   Review the logs above and fix any issues"
  echo "   For guidance, see docs/workflow_testing_guide.md"
fi

exit $ISSUES_FOUND
