#!/bin/bash

# Script to set up branch protection for the main branch using GitHub CLI
# This requires GitHub CLI to be installed and authenticated

# Define repository (assuming it matches the directory name)
REPO=$(basename $(pwd))
OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')

echo "Setting up branch protection for $OWNER/$REPO main branch"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it first."
    echo "Visit https://cli.github.com/ for installation instructions."
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Create branch protection rule
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$REPO/branches/main/protection" \
  -f required_status_checks='{"strict":true,"contexts":["security-scan","backend-lint-test (lint)","backend-lint-test (test)","frontend-lint-test"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  -f restrictions=null

echo "Branch protection rule created for main branch"
