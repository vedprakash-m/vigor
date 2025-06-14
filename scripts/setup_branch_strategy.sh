#!/bin/bash
# Script to implement the simplified branch management strategy

echo "Implementing simplified branch management strategy for Vigor..."

# Function to check if on main branch
check_on_main() {
  current_branch=$(git branch --show-current)
  if [ "$current_branch" != "main" ]; then
    echo "❌ ERROR: You need to be on the main branch to run this script."
    echo "Current branch: $current_branch"
    echo "Please run: git checkout main"
    exit 1
  fi
}

# Function to ensure main branch is up to date
update_main() {
  echo "🔄 Updating main branch from remote..."
  git fetch origin
  git pull origin main

  if [ $? -ne 0 ]; then
    echo "❌ Failed to update main branch. Please resolve conflicts and try again."
    exit 1
  fi
}

# Create develop branch
create_develop_branch() {
  echo "🌿 Creating/updating develop branch..."

  # Check if develop branch exists locally
  if git rev-parse --verify develop > /dev/null 2>&1; then
    echo "Develop branch exists locally, updating it..."
    git checkout develop
    git pull origin develop || git pull origin main
  else
    # Check if develop branch exists remotely
    if git ls-remote --heads origin develop > /dev/null 2>&1; then
      echo "Develop branch exists remotely, checking out..."
      git checkout -b develop origin/develop
    else
      echo "Creating new develop branch from main..."
      git checkout -b develop main
    fi
  fi

  # Push develop branch if it doesn't exist remotely
  if ! git ls-remote --heads origin develop > /dev/null 2>&1; then
    echo "Pushing develop branch to remote..."
    git push -u origin develop
  fi

  # Return to main branch
  git checkout main
}

# Setup branch protection for main branch
setup_main_protection() {
  echo "🔒 Setting up branch protection for main branch..."

  # Create a JSON file for branch protection settings
  cat > branch_protection_main.json << EOF
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
    "required_approving_review_count": 1,
    "bypass_pull_request_allowances": {}
  },
  "restrictions": null
}
EOF

  # Apply branch protection using GitHub CLI
  echo "Applying protection rules to main branch..."
  REPO=$(basename $(pwd))
  OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')

  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$OWNER/$REPO/branches/main/protection" \
    --input branch_protection_main.json

  if [ $? -ne 0 ]; then
    echo "❌ Failed to set up branch protection for main. Make sure you have admin access."
    echo "You can manually set up branch protection through the GitHub web interface."
  else
    echo "✅ Branch protection applied for main branch"
  fi
}

# Setup branch protection for develop branch
setup_develop_protection() {
  echo "🔒 Setting up branch protection for develop branch..."

  # Create a JSON file for branch protection settings
  cat > branch_protection_develop.json << EOF
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "security-scan",
      "backend-lint-test (lint)",
      "backend-lint-test (test)",
      "frontend-lint-test"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF

  # Apply branch protection using GitHub CLI
  echo "Applying protection rules to develop branch..."
  REPO=$(basename $(pwd))
  OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\)\/[^/]*.*/\1/p')

  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$OWNER/$REPO/branches/develop/protection" \
    --input branch_protection_develop.json

  if [ $? -ne 0 ]; then
    echo "❌ Failed to set up branch protection for develop. Make sure you have admin access."
    echo "You can manually set up branch protection through the GitHub web interface."
  else
    echo "✅ Branch protection applied for develop branch"
  fi
}

# Consolidate current feature branches
consolidate_branches() {
  echo "🔄 Consolidating existing feature branches..."

  # Check if we need to merge the CI/CD fixes branch
  if git branch | grep -q "fix-cicd-issues-"; then
    read -p "Do you want to merge the CI/CD fixes branch to main? (y/n) " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
      cicd_branch=$(git branch | grep "fix-cicd-issues-" | sed 's/^[ *]*//')
      echo "Merging $cicd_branch to main..."
      git checkout main
      git merge --squash "$cicd_branch"
      git commit -m "Merge CI/CD fixes from $cicd_branch"
      git push origin main
    fi
  fi

  # Check if we need to merge the update-metadata branch
  if git branch | grep -q "update-metadata"; then
    read -p "Do you want to merge the update-metadata branch to main? (y/n) " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
      git checkout main
      git merge --squash update-metadata
      git commit -m "Merge metadata updates from update-metadata branch"
      git push origin main
    fi
  fi

  # Return to main branch
  git checkout main
}

# Clean up stale branches
cleanup_branches() {
  echo "🧹 Cleaning up merged and stale branches..."

  # List merged branches
  echo "Branches that have been merged and can be deleted:"
  git branch --merged | grep -v "\*\|main\|develop"

  # Prompt for automatic cleanup
  read -p "Do you want to delete these merged branches? (y/n) " answer
  if [[ $answer =~ ^[Yy]$ ]]; then
    git branch --merged | grep -v "\*\|main\|develop" | xargs -r git branch -d
    echo "Local merged branches deleted"
  fi

  # Check for remote branches that can be pruned
  git remote prune origin --dry-run
  read -p "Do you want to prune these remote branches? (y/n) " answer
  if [[ $answer =~ ^[Yy]$ ]]; then
    git remote prune origin
    echo "Remote tracking branches pruned"
  fi
}

# Create documentation
create_documentation() {
  echo "📝 Creating branch management documentation..."

  # Documentation already created, let's make sure it's committed
  git add docs/BRANCH_MANAGEMENT.md
  git commit -m "Add branch management documentation"
  git push origin main
}

# Main execution
main() {
  check_on_main
  update_main
  create_develop_branch
  setup_main_protection
  setup_develop_protection
  consolidate_branches
  cleanup_branches
  create_documentation

  echo "✅ Branch management strategy implemented successfully!"
  echo "See docs/BRANCH_MANAGEMENT.md for the complete documentation."
}

# Execute main function
main
