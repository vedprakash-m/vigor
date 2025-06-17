#!/bin/bash
# Script to close all open PRs using GitHub CLI

echo "🔄 Closing all open Pull Requests..."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
    exit 1
fi

# Get all open PR numbers and close them
gh pr list --state open --json number --jq '.[].number' | while read pr_number; do
    echo "Closing PR #$pr_number..."
    gh pr close "$pr_number" --comment "Closing as part of project cleanup. All Dependabot PRs are being consolidated."
done

echo "✅ All PRs have been closed."
echo "📊 Remaining open PRs:"
gh pr list --state open
