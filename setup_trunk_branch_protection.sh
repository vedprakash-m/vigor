#!/bin/bash
# Script to implement a streamlined trunk-based development workflow branch protection

echo "Implementing streamlined trunk-based development branch protection..."

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
    "required_approving_review_count": 1
  },
  "restrictions": null
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

# Create PR template
mkdir -p .github
cat > .github/pull_request_template.md << EOF
### 🔧 What does this PR do?

### 📌 Why is it needed?

### 🧪 How was it tested?

### ✅ Checklist
- [ ] Tiny scope (≤ 300 LOC)
- [ ] CI passes (lint, test, build)
- [ ] Code reviewed
- [ ] Safe to squash & merge
EOF

echo "✅ Pull request template created"
echo "Branch protection setup complete for streamlined trunk-based development!"
echo "See docs/branch_enforcement_guide.md for complete details on the workflow."

# Clean up
rm branch_protection.json
