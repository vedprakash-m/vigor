# Automated PR Merge Process

This document explains how our automated PR merge process works, helping you get changes into the main branch without manual intervention while maintaining all necessary guardrails.

## Overview

We've implemented an automated PR triage, validation, and merge system that:

1. Analyzes every PR against our quality standards
2. Provides immediate feedback on PR status
3. Automatically merges PRs that meet all criteria
4. Maintains all branch protection guardrails

## Getting Your PR Auto-Merged

For your PR to be automatically merged to `main`, it must:

1. Have the `auto-merge` label applied
2. Be 300 LOC or smaller (excluding lock files)
3. Include tests (unless it's a hotfix)
4. Pass all required CI checks
5. Have the required number of approvals
6. Not be a draft PR or from a fork

## How to Use Auto-Merge

### Step 1: Create Your PR

Follow the trunk-based development workflow:

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature
# Make your changes (keep it small!)
git add .
git commit -m "Your commit message"
git push origin feature/your-feature
# Create PR via GitHub UI
```

### Step 2: Add the Auto-Merge Label

After creating your PR:

1. Go to your PR on GitHub
2. Click on the gear icon next to "Labels" in the right sidebar
3. Select the `auto-merge` label

### Step 3: Address the Validation Status

The workflow will automatically comment on your PR with a validation status:

```
## PR Validation Status

- ✅ Small PR (≤ 300 LOC)
- ✅ Has Tests or Hotfix
- ✅ Auto-merge Label

✨ Auto-merge eligible! Will merge after required checks pass.
```

If any criteria aren't met, the comment will explain what needs to be fixed.

### Step 4: Wait for Checks and Reviews

Once your PR:

1. Passes all required CI checks
2. Receives the required number of approvals
3. Meets all auto-merge criteria

It will be automatically merged into `main` using squash merge, and the branch will be deleted.

## Guardrails

This system maintains all branch protection rules:

- Required status checks must pass
- Required reviews must be submitted
- Branch protection rules are never bypassed
- PRs must meet our quality standards (size, tests)

## Manual Intervention

For PRs that don't qualify for auto-merge (large changes, etc.), you'll need to:

1. Get the required approvals
2. Ensure all checks pass
3. Merge manually through the GitHub UI

## Hotfix Fast-Track

For urgent fixes using the `hotfix/*` branch naming convention:

1. The test requirement is relaxed
2. These still require the `auto-merge` label and CI checks to pass
3. They follow the same size constraints (≤ 300 LOC)
