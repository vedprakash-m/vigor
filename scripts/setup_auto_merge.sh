#!/bin/bash
# Set up auto-merge label and branch protection in GitHub repo

echo "Setting up auto-merge label and branch protection..."

# Get repository information
REPO=$(basename $(pwd))
OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')
echo "Repository: $OWNER/$REPO"

# Create auto-merge label
echo "Creating auto-merge label..."
gh label create "auto-merge" \
  --color "0E8A16" \
  --description "PRs labeled with this will be automatically merged when all checks pass"

# Create do-not-merge label
echo "Creating do-not-merge label..."
gh label create "do-not-merge" \
  --color "B60205" \
  --description "PRs labeled with this will not be auto-merged regardless of other settings"

# Update branch protection rules to work with auto-merge
echo "Updating branch protection rules..."

# Create a JSON file for branch protection settings
cat > branch_protection.json << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "security-scan",
      "backend-lint-test (lint)",
      "backend-lint-test (test)",
      "frontend-lint-test",
      "pr-verification"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
EOF

# Apply branch protection using GitHub CLI
echo "Applying protection rules to main branch..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$OWNER/$REPO/branches/main/protection" \
  --input branch_protection.json

if [ $? -ne 0 ]; then
  echo "❌ Failed to set up branch protection for main. Make sure you have admin access."
  echo "You can manually set up branch protection through the GitHub web interface."
else
  echo "✅ Branch protection applied for main branch"
fi

# Clean up
rm branch_protection.json

echo "✅ Auto-merge setup complete!"
echo "You can now label PRs with 'auto-merge' to have them automatically merged when all conditions are met."
echo "For more information, see docs/dev_pr_mgmt.md"
