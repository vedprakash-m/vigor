#!/bin/bash

# Script to fix the CI/CD issues and commit changes

echo "🔧 Fixing CI/CD issues..."

# Make sure we're in the root directory
cd "$(dirname "$0")"

# Create a new branch for the changes
BRANCH_NAME="fix-cicd-issues-$(date +%Y%m%d%H%M%S)"
git checkout -b "$BRANCH_NAME"

echo "📝 Committing changes..."
git add .github/workflows/ci_cd_pipeline_combined.yml
git add backend-app-service-job.yml
git add function-app-job.yml
git add static-web-app-job.yml

git commit -m "Fix CI/CD workflow issues and standardize job format

- Fixed indentation and structure in all workflow files
- Standardized job definitions across all deployment files
- Added proper triggers and job names
- Fixed token handling and environment variable references
- Created combined workflow file as a single source of truth
- Added better error handling for secret validation"

echo "🚀 Pushing changes to origin/$BRANCH_NAME..."
git push origin "$BRANCH_NAME"

echo "✅ Changes pushed successfully!"
echo "Create a pull request from branch $BRANCH_NAME to merge the CI/CD fixes."
echo "Visit: https://github.com/username/vigor/pull/new/$BRANCH_NAME"
