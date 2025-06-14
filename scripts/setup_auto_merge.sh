#!/bin/bash
# Script to set up the auto-merge label in your GitHub repository

echo "🏷️  Setting up auto-merge label in GitHub repository..."

# Get repository information
REPO=$(basename $(pwd))
OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')
echo "Repository: $OWNER/$REPO"

# Create auto-merge label with a nice green color
echo "Creating auto-merge label..."
gh label create auto-merge \
  --color 0E8A16 \
  --description "PRs with this label will be auto-merged when checks pass" \
  || echo "Label may already exist"

echo "✅ Auto-merge label setup complete!"
echo ""
echo "To enable auto-merge for PRs:"
echo "1. Apply the 'auto-merge' label to the PR"
echo "2. Ensure PR is ≤ 300 LOC"
echo "3. Include tests (unless it's a hotfix)"
echo "4. Get the required approvals"
echo ""
echo "See docs/AUTO_MERGE_PROCESS.md for more details"
