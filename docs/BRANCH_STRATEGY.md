# Vigor Branch Strategy: Streamlined Trunk-Based Development

This document outlines our streamlined trunk-based development workflow, optimized for both speed and stability.

## Core Principles

- **Speed**: Fast integrations and deployments
- **Simplicity**: Minimal workflow friction
- **Stability**: Always deployable main branch
- **Quality**: Rigorous automated testing

## Branch Structure

### Primary Branch

- **`main`** - The trunk/production branch
  - Protected with strict rules
  - Always deployable
  - No direct commits allowed

### Short-lived Branches

All work happens in short-lived branches that merge directly back to `main`:

- **`feature/...`** - For new features and non-urgent fixes

  - Created from and merged back to `main`
  - Short-lived (max 3 days)
  - Tiny scope (≤ 300 LOC changes)

- **`hotfix/...`** - For urgent production fixes

  - Created from and merged back to `main`
  - Highest priority for review
  - Deployed immediately after merge

- **`dependabot/...`** - Automated dependency updates
  - Generated automatically
  - Require review before merge

## Development Workflow

```
main ──────────┬─────────────┬─────────┬─────── (always deployable)
               │             │         │
feature/a ─────┘             │         │        (≤ 300 LOC, ≤ 3 days)
                          ↙  │         │
                 feature/b ──┘         │        (small, focused change)
                                    ↙  │
                          hotfix/c ────┘        (urgent fix)
```

### Creating a New Feature

```bash
# Start from latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Work, commit, and push
git push -u origin feature/your-feature-name

# Create PR to main (via GitHub UI)
```

### Making a Hotfix

```bash
# Start from latest main
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/your-urgent-fix

# Make fix, commit, and push
git push -u origin hotfix/your-urgent-fix

# Create PR to main (via GitHub UI) with high priority
```

## Pull Request Requirements

- Small scope (≤ 300 LOC changes)
- Clear description of changes and testing
- Passes all CI checks
- At least one code review approval
- Squash & Merge to maintain clean history

## Branch Protection Rules

- Require passing status checks before merging
- Require up-to-date branches before merging
- Require at least one approval
- Dismiss stale approvals when new commits are pushed
- Enforce all these rules for administrators too

## Special Cases

### Complex Features

For larger features that exceed the 300 LOC guideline:

1. Break down into smaller, independently valuable chunks
2. Create sequential PRs, each with clear scope
3. If truly inseparable, justify in PR description and request additional reviews

### Multiple Concurrent Features

- Work in separate feature branches
- Rebase frequently on main to reduce merge conflicts
- Consider pair programming for related features to avoid conflicts

## Quality Standards

- Write tests for new features
- Keep functions and components small
- Follow existing style/lint rules
- Maintain a clean, linear commit history in `main`
- Use clear, descriptive commit messages

## Measuring Success

Our process is working well when:

- PRs are merged within 1-2 days
- CI is consistently passing on all branches
- Merge conflicts are rare and minor
- Features reach production quickly and stably
- Team members report minimal friction

> **Remember**: The goal is rapid, stable delivery. Small, focused changes are easier to review, integrate, and roll back if needed.
