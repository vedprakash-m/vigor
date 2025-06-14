#!/bin/bash
# Script to set up branch protection rules for trunk-based development

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
      "CI Checks"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Apply branch protection using GitHub CLI
echo "Applying branch protection rules..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$OWNER/$REPO/branches/main/protection" \
  --input branch_protection.json

if [ $? -ne 0 ]; then
  echo "❌ Failed to set up branch protection. Make sure you have admin access and GitHub CLI installed."
  echo "You can manually set up branch protection through the GitHub web interface."
else
  echo "✅ Branch protection rules applied successfully for main branch"
fi

# Set up repository settings for squash merges
echo "Setting repository merge options..."
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$OWNER/$REPO" \
  -f allow_squash_merge=true \
  -f allow_merge_commit=false \
  -f allow_rebase_merge=false \
  -f delete_branch_on_merge=true

if [ $? -ne 0 ]; then
  echo "❌ Failed to set merge options. Make sure you have admin access."
else
  echo "✅ Repository configured to use squash merges and delete branches after merging"
fi

# Create CODEOWNERS file if it doesn't exist
if [ ! -f ".github/CODEOWNERS" ]; then
  mkdir -p .github
  echo "# CODEOWNERS file
# See: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

# Default owners for everything
* @$OWNER

# Add specific owners for different parts of the codebase
# /frontend/ @frontend-team
# /backend/ @backend-team
# /docs/ @docs-team
" > .github/CODEOWNERS
  echo "✅ Created CODEOWNERS template file"
fi

# Clean up
rm branch_protection.json

echo ""
echo "Branch protection setup complete! Here's what was configured:"
echo "✓ Required status checks"
echo "✓ Required pull request reviews"
echo "✓ Enforced for administrators"
echo "✓ Required linear history"
echo "✓ Repository configured for squash merges"
echo "✓ Branch deletion on merge"
echo ""
echo "To complete setup, run the setup_auto_merge.sh script next!"
