#!/bin/bash
# Setup minimal but effective branch protection for main

echo "🛡️ Setting up optimal branch protection for main branch..."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
    exit 1
fi

# Get current repo info
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
echo "📁 Repository: $REPO"

# Set up branch protection with minimal but effective rules
echo "🔧 Configuring branch protection rules..."

gh api \
  --method PUT \
  --header "Accept: application/vnd.github.v3+json" \
  "/repos/$REPO/branches/main/protection" \
  --field required_status_checks[strict]=true \
  --field required_status_checks[contexts][]="Quality Checks" \
  --field enforce_admins=false \
  --field required_pull_request_reviews=null \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false

echo "✅ Branch protection configured successfully!"
echo ""
echo "🎯 Protection Summary:"
echo "   ✅ Require status checks: Quality Checks must pass"
echo "   ✅ Require up-to-date branches: No stale pushes"
echo "   ✅ Linear history: Clean git history"
echo "   ❌ No PR reviews required: Fast iteration"
echo "   ❌ No admin restrictions: Trust but verify"
echo ""
echo "🚀 Developers can now:"
echo "   • Push directly to main (after CI passes)"
echo "   • Create feature branches if needed (optional)"
echo "   • Rely on comprehensive CI/CD for quality gates"
