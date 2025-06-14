# 🔒 Vigor Branch Strategy: Streamlined Trunk-Based Development

This document serves as a single source of truth for our streamlined trunk-based development workflow, optimized for both speed and stability.

---

## 🌳 Core Branching Strategy

We follow a **lean trunk-based development model** with minimal friction:

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

---

## 🔄 Development Workflow

1. Start from the latest `main`:

   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```

2. Make focused, incremental changes
3. Push and open a PR to `main`
4. Address CI feedback and reviewer comments
5. Merge using **Squash & Merge**

---

## 💡 Key Principles

- **Small scoped changes** - PRs should be small and focused
- **Short-lived branches** - Branches should be merged within 3 days
- **Continuous integration** - Frequent merges to `main`
- **Always deployable** - `main` must always be stable
- **Automated validation** - All changes pass CI before merge

---

## ✅ CI Setup (GitHub Actions)

**File:** `.github/workflows/ci.yml`

```yaml
name: CI Checks

on:
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: 18

      - name: Install dependencies
        run: npm install

      - name: Lint
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build
```

---

## 📝 Pull Request Template

**File:** `.github/pull_request_template.md`

```md
### 🔧 What does this PR do?

### 📌 Why is it needed?

### 🧪 How was it tested?

### ✅ Checklist

- [ ] Tiny scope (≤ 300 LOC)
- [ ] CI passes (lint, test, build)
- [ ] Code reviewed
- [ ] Safe to squash & merge
```

- Use **Squash & Merge**

## 🧰 CI/CD

- We use GitHub Actions (`.github/workflows/ci.yml`) to enforce build and test quality
- Never merge failing PRs

## ✅ Quality Standards

- Write tests for new features
- Keep functions and components small
- Follow existing style/lint rules

````

---

## 🔐 Branch Protection Rules

> Apply manually or via CLI

**Command:**

```bash
gh api --method PUT /repos/OWNER/REPO/branches/main/protection \
  -f required_status_checks.strict=true \
  -f required_status_checks.contexts[]='CI Checks' \
  -f enforce_admins=true \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f restrictions=null \
  -H "Accept: application/vnd.github+json"
````

> Replace `OWNER` and `REPO` with your GitHub organization and repository names.

---

## � Automated PR Process

We use GitHub Actions to automate the Pull Request approval and merge process while maintaining all necessary guardrails.

### Auto-Merge Setup

**File:** `.github/workflows/auto-merge.yml`

```yaml
name: Automated PR Processing

on:
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
      - labeled
      - unlabeled
  check_suite:
    types:
      - completed
  status: {}

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: |
      github.event.pull_request.user.login != 'dependabot[bot]' &&
      contains(github.event.pull_request.labels.*.name, 'auto-merge') &&
      github.event.pull_request.draft == false
    steps:
      - name: Auto-merge qualifying PRs
        uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          MERGE_METHOD: "squash"
          MERGE_LABELS: "auto-merge,!do-not-merge"
          MERGE_REMOVE_LABELS: "auto-merge"
          MERGE_COMMIT_MESSAGE: "pull-request-title"
          MERGE_RETRIES: "6"
          MERGE_RETRY_SLEEP: "10000"
          UPDATE_LABELS: "auto-merge"
          UPDATE_METHOD: "rebase"

  pr-verification:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Verify PR size
        id: verify-pr-size
        run: |
          PR_FILES=$(gh pr view ${{ github.event.pull_request.number }} --json files -q '.files[].path')
          PR_ADDITIONS=$(gh pr view ${{ github.event.pull_request.number }} --json additions -q '.additions')
          PR_DELETIONS=$(gh pr view ${{ github.event.pull_request.number }} --json deletions -q '.deletions')
          PR_CHANGES=$((PR_ADDITIONS + PR_DELETIONS))

          echo "PR has $PR_CHANGES changes ($PR_ADDITIONS additions, $PR_DELETIONS deletions)"

          if [[ $PR_CHANGES -gt 300 ]]; then
            echo "::warning::This PR exceeds the recommended 300 lines limit. Please consider breaking it into smaller PRs."
            echo "size_warning=true" >> $GITHUB_OUTPUT
          else
            echo "size_warning=false" >> $GITHUB_OUTPUT
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### How to Use Auto-Merge

1. Create your PR as usual
2. Ensure all CI checks pass
3. Get the required review approvals
4. Apply the `auto-merge` label to eligible PRs
5. The PR will be automatically merged once all requirements are met:
   - All CI checks pass
   - Required number of approvals is met
   - Has the `auto-merge` label
   - Is not a draft PR
   - Doesn't have the `do-not-merge` label

### Guardrails

The auto-merge workflow includes these guardrails:

- **Required CI Passing**: Will not merge if any required checks fail
- **Required Reviews**: Respects branch protection requiring approved reviews
- **Size Warning**: Warns if PR exceeds 300 lines of changes
- **Cancel Option**: Can remove auto-merge by removing the label or adding a `do-not-merge` label
- **Human Control**: Only merges PRs explicitly labeled for auto-merge
- **No Drafts**: Does not merge draft PRs

---

## 🧠 Summary

1. Place all code into the correct files as listed above.
2. Apply the branch protection rule via GitHub CLI.
3. Enforce squash merges, CI passing status, and 1+ reviewer on `main`.
4. Warn if:
   - PR > 300 LOC
   - PR is open > 2 days
   - PR lacks tests or description
5. Use auto-merge labels for eligible PRs that should be automatically merged.
6. Maintain a clean, linear commit history in `main`.

---
