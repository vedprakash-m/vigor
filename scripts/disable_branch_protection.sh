#!/bin/bash

# Disable branch protection temporarily for a major release
# Usage: ./disable_branch_protection.sh [enable|disable]

# Configuration
REPO=$(basename $(pwd))
OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')
BRANCH="main"
ACTION=${1:-"disable"}  # Default to disable

echo "==== BRANCH PROTECTION OVERRIDE ===="
echo "Repository: $OWNER/$REPO"
echo "Branch: $BRANCH"
echo "Action: $ACTION"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

if [ "$ACTION" == "disable" ]; then
    echo "Disabling branch protection for $BRANCH..."

    # Use GitHub API to disable branch protection
    gh api \
      --method DELETE \
      "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
      -H "Accept: application/vnd.github.v3+json"

    if [ $? -eq 0 ]; then
        echo "✅ Branch protection successfully disabled for $BRANCH"
        echo "WARNING: Branch is now unprotected. Re-enable protection after your changes."
        echo "To re-enable protection, run: $0 enable"
    else
        echo "❌ Failed to disable branch protection. Check your permissions."
        exit 1
    fi
elif [ "$ACTION" == "enable" ]; then
    echo "Re-enabling branch protection for $BRANCH..."

    # Create basic branch protection settings
    cat > /tmp/branch_protection.json << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci-build", "security-scan", "test-coverage"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF

    # Use GitHub API to re-enable branch protection
    gh api \
      --method PUT \
      "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
      -H "Accept: application/vnd.github.v3+json" \
      --input /tmp/branch_protection.json

    if [ $? -eq 0 ]; then
        echo "✅ Branch protection successfully re-enabled for $BRANCH"
        rm /tmp/branch_protection.json
    else
        echo "❌ Failed to re-enable branch protection. Please configure it manually in GitHub settings."
        echo "Settings URL: https://github.com/$OWNER/$REPO/settings/branches"
        exit 1
    fi
else
    echo "Invalid action. Use 'enable' or 'disable'."
    exit 1
fi
