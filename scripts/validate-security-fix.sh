#!/bin/bash
# Validates a security fix PR is properly scoped and formatted

set -eo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <pr-number>"
  exit 1
fi

PR_NUMBER=$1

echo "🔎 Validating security fix PR #$PR_NUMBER..."

# Get PR details
PR_LABELS=$(gh pr view $PR_NUMBER --json labels -q '.labels[].name')
PR_FILES=$(gh pr view $PR_NUMBER --json files -q '.files[].path')
PR_DESCRIPTION=$(gh pr view $PR_NUMBER --json body -q '.body')
PR_TITLE=$(gh pr view $PR_NUMBER --json title -q '.title')

# Check labels
if ! echo "$PR_LABELS" | grep -q "security-fix"; then
  echo "⚠️  Warning: Missing 'security-fix' label"
fi

# Check title doesn't expose details
if echo "$PR_TITLE" | grep -iE '(vulnerability|exploit|injection|xss|csrf|cve)'; then
  echo "⚠️  Warning: PR title may expose security details"
fi

# Check description privacy
if echo "$PR_DESCRIPTION" | grep -iE '(vulnerability details|exploit|payload|injection vector)'; then
  echo "⚠️  Warning: PR description may contain sensitive details"
fi

# Check code focus
FILE_COUNT=$(echo "$PR_FILES" | wc -l)
if [ "$FILE_COUNT" -gt 10 ]; then
  echo "⚠️  Warning: Security fix modifies $FILE_COUNT files - consider narrowing scope"
fi

echo "✅ Validation complete - review warnings (if any)"
