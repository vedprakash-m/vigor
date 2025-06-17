#!/bin/bash
# Script to close all open issues using GitHub CLI

echo "🔄 Closing all open Issues..."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
    exit 1
fi

# Get all open issue numbers and close them
gh issue list --state open --json number --jq '.[].number' | while read issue_number; do
    echo "Closing Issue #$issue_number..."
    gh issue close "$issue_number" --comment "Closing as part of project cleanup and CI/CD simplification.

The complex deployment pipeline has been replaced with a cost-optimized single-slot deployment strategy. Previous deployment failures are resolved with the new simplified CI/CD approach.

Refer to docs/metadata.md for updated architecture and deployment strategy."
done

echo "✅ All issues have been closed."
echo "📊 Remaining open issues:"
gh issue list --state open
