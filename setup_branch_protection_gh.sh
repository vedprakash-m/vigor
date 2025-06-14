#!/bin/bash
# Set up branch protection using GitHub CLI with proper JSON formatting

# Get repository information
REPO=$(basename $(pwd))
OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')
echo "Setting up branch protection for $OWNER/$REPO main branch"

# Create a JSON file for branch protection settings
cat > branch_protection.json << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "security-scan",
      "backend-lint-test (lint)",
      "backend-lint-test (test)",
      "frontend-lint-test"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF

# Apply branch protection using GitHub CLI
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$OWNER/$REPO/branches/main/protection" \
  --input branch_protection.json

echo "Branch protection rules applied for main branch"

# Clean up
rm branch_protection.json
