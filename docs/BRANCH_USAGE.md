# Quick Guide to Branch Usage

## Starting a New Feature

```bash
# Make sure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create a feature branch
git checkout -b feature/your-feature-name

# Work on your changes...

# Push to remote (first time)
git push -u origin feature/your-feature-name

# Create PR to develop when ready (via GitHub UI)
```

## Making a Hotfix

```bash
# Make sure you're on main and it's up to date
git checkout main
git pull origin main

# Create a hotfix branch
git checkout -b hotfix/your-hotfix-name

# Work on your emergency fix...

# Push to remote
git push -u origin hotfix/your-hotfix-name

# Create PR to main when ready (via GitHub UI)
# After merging to main, also merge to develop:
git checkout develop
git pull origin develop
git merge origin/main
git push origin develop
```

## Cleaning Up

```bash
# Delete local branches that have been merged
git checkout main
git branch --merged | grep -v "\*\|main\|develop" | xargs git branch -d

# Prune remote branches that no longer exist
git remote prune origin
```

## Common Workflows

### Normal Feature Development

1. Create feature branch from develop
2. Make changes
3. Open PR to develop
4. After approval, merge to develop

### Release Process

1. Create PR from develop to main
2. Review and test changes
3. After approval, merge to main

### Emergency Hotfix

1. Create hotfix branch from main
2. Make and test emergency fix
3. Open PR to main
4. After approval, merge to main
5. Merge main back to develop

## Branch Protection

- **main**: Protected, requires PR and approvals
- **develop**: Semi-protected, requires passing tests
