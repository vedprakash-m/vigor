#!/bin/bash

# Script to set up branch protection for the main branch
# This provides instructions for setting up branch protection manually

echo "====================== BRANCH PROTECTION SETUP ======================"
echo "To enable branch protection for the main branch, follow these steps:"
echo
echo "1. Go to the GitHub repository settings:"
echo "   https://github.com/your-username/vigor/settings/branches"
echo
echo "2. Under 'Branch protection rules', click 'Add rule'"
echo
echo "3. Enter 'main' as the branch name pattern"
echo
echo "4. Check the following options:"
echo "   ✓ Require a pull request before merging"
echo "   ✓ Require approvals (set to 1)"
echo "   ✓ Dismiss stale pull request approvals when new commits are pushed"
echo "   ✓ Require review from Code Owners"
echo
echo "5. Check 'Require status checks to pass before merging'"
echo "   ✓ Require branches to be up to date before merging"
echo "   ✓ Search and select the following status checks:"
echo "     - security-scan"
echo "     - backend-lint-test (lint)"
echo "     - backend-lint-test (test)"
echo "     - frontend-lint-test"
echo
echo "6. Check 'Do not allow bypassing the above settings'"
echo
echo "7. Click 'Create' to save the rule"
echo
echo "For documentation purposes, these settings have been recorded in:"
echo "/docs/BRANCH_PROTECTION_IMPLEMENTED.md"
echo "===================================================================="
