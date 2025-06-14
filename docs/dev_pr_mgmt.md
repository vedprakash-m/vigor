# 🤖 Development & PR Management Guide

This document serves as a complete implementation guide for setting up a fully automated development workflow and pull request management system, optimized for both speed and stability. Any project can use this guide to implement a similar fully automated development process.

---

## 📋 Quick Start Implementation

To implement this strategy in your project, follow these steps:

1. **Create Required Files Structure**:

   ```bash
   # Create necessary directories
   mkdir -p .github/workflows

   # Copy files from this guide or create them from scratch
   touch .github/workflows/ci.yml
   touch .github/workflows/auto-merge.yml
   touch .github/workflows/pr-lifecycle.yml
   touch .github/workflows/pr-classifier.yml
   touch .github/workflows/auto-approve.yml
   touch .github/workflows/coverage-check.yml
   touch .github/workflows/post-merge-monitor.yml
   touch .github/workflows/workflow-health-check.yml
   touch .github/workflows/auto-merge-security.yml
   touch .github/workflows/auto-approve-security.yml
   touch .github/workflows/pr-audit-trail.yml
   touch .github/pull_request_template.md
   ```

2. **Set Up Workflow Files**:

   - Copy the CI workflow content into `.github/workflows/ci.yml` (from the CI Setup section)
   - Copy the auto-merge workflow content into `.github/workflows/auto-merge.yml` (from the Auto-Merge Setup section)
   - Copy the post-merge monitoring content into `.github/workflows/post-merge-monitor.yml` (from the Post-Merge Monitoring section)
   - See `docs/agent_communication_guide.md` for how to communicate with coding agents about overrides and bypasses
   - See `docs/ci_optimization_guide.md` for improving CI/CD performance
   - See `docs/feedback_implementation.md` for implementation details of safety and monitoring enhancements
   - See `docs/secrets_management_guide.md` for secure handling of tokens and secrets in workflows
   - See `docs/workflow_testing_guide.md` for ensuring workflows remain error-free and don't become bottlenecks
   - Copy the PR lifecycle management workflow content into `.github/workflows/pr-lifecycle.yml` (from the Automated PR Management section)
   - Copy the PR classifier workflow content into `.github/workflows/pr-classifier.yml` (from the Automated PR Management section)
   - Copy the auto-approve workflow content into `.github/workflows/auto-approve.yml` (from the Automated PR Management section)
   - Copy the coverage check workflow content into `.github/workflows/coverage-check.yml` (from the Test Coverage Enforcement section)
   - Copy the PR template content into `.github/pull_request_template.md` (from the Pull Request Template section)
   - Customize job names and steps as needed for your project

3. **Create Implementation Scripts**:

   ```bash
   # Create and make scripts executable
   touch branch-protection.sh
   touch setup_auto_merge.sh
   chmod +x branch-protection.sh
   chmod +x setup_auto_merge.sh

   # Copy script contents from the Implementation Scripts section
   ```

4. **Run Setup Scripts**:

   ```bash
   # Execute branch protection setup
   ./branch-protection.sh

   # Execute auto-merge configuration
   ./setup_auto_merge.sh
   ```

5. **Add CODEOWNERS File** (optional but recommended):
   ```bash
   mkdir -p .github
   echo "# CODEOWNERS file
   ```

# Default owners for everything

- @your-username" > .github/CODEOWNERS

  ```

  ```

6. **Validate Your Setup**:

   - Follow the validation checklist in the Validation and Testing section
   - Create a test PR to confirm everything works as expected

7. **Educate Your Team**:
   - Share this guide with all contributors
   - Emphasize the importance of small, focused PRs
   - Explain the auto-merge process and labels

The complete implementation details are provided in the sections below.

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
  push:
    branches: [main]

jobs:
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run SAST scan
        uses: github/codeql-action/init@v2
        with:
          languages: javascript, typescript, python

      - name: Perform SAST analysis
        uses: github/codeql-action/analyze@v2

  frontend-lint-test:
    name: Frontend Lint & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: "npm"
          cache-dependency-path: "frontend/package-lock.json"

      - name: Install dependencies
        working-directory: frontend
        run: npm ci

      - name: Lint
        working-directory: frontend
        run: npm run lint

      - name: Run tests
        working-directory: frontend
        run: npm test

      - name: Build
        working-directory: frontend
        run: npm run build

  backend-lint-test:
    name: Backend Lint & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.10"
          cache: "pip"
          cache-dependency-path: "backend/requirements*.txt"

      - name: Install dependencies
        working-directory: backend
        run: pip install -r requirements-dev.txt

      - name: Lint
        working-directory: backend
        run: |
          black --check .
          flake8 .
          isort --check .

      - name: Test
        working-directory: backend
        run: pytest -v
```

---

## 📝 Pull Request Template

**File:** `.github/pull_request_template.md`

```md
### 🔧 What does this PR do?

<!-- Provide a clear and concise description of the changes -->

### 📌 Why is it needed?

<!-- Explain the business value or technical need for these changes -->

### 🧪 How was it tested?

<!-- Describe the testing you've done to validate your changes -->

### 📚 Related issues

<!-- Link to any related issues using #issue-number format -->

### ✅ Checklist

- [ ] Tiny scope (≤ 300 LOC)
- [ ] CI passes (lint, test, build)
- [ ] Code reviewed
- [ ] Tests added/updated for new functionality
- [ ] Documentation updated (if applicable)
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
```

> Replace `OWNER` and `REPO` with your GitHub organization and repository names.

---

## 🤖 Automated PR Process

We use GitHub Actions to automate the Pull Request approval and merge process while maintaining all necessary guardrails. This reduces manual effort while ensuring code quality.

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
      (github.event.pull_request.user.login != 'dependabot[bot]') &&
      (contains(github.event.pull_request.labels.*.name, 'auto-merge') || contains(github.event.pull_request.labels.*.name, 'emergency-override')) &&
      github.event.pull_request.draft == false &&
      !contains(github.event.pull_request.labels.*.name, 'do-not-merge')
    steps:
      - name: Check release mode
        id: check-release-mode
        run: |
          # Check if auto-merge is disabled in release mode
          if [ -f ".github/release-config.json" ]; then
            release_mode_enabled=$(jq -r '.releaseMode.enabled // false' .github/release-config.json)
            auto_merge_disabled=$(jq -r '.releaseMode.relaxedRules.autoMergeDisabled // false' .github/release-config.json)

            if [[ "$release_mode_enabled" == "true" && "$auto_merge_disabled" == "true" && ! "${{ contains(github.event.pull_request.labels.*.name, 'emergency-override') }}" == "true" ]]; then
              echo "Auto-merge disabled during release mode except for emergency overrides"
              exit 1
            fi
          fi

      - name: Auto-merge qualifying PRs
        uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          MERGE_METHOD: "squash"
          MERGE_LABELS: "auto-merge,emergency-override,!do-not-merge"
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
          # Check for override labels first
          has_override=${{ contains(github.event.pull_request.labels.*.name, 'size-limit-exempt') || contains(github.event.pull_request.labels.*.name, 'priority-release') || contains(github.event.pull_request.labels.*.name, 'emergency-override') }}

          # Check for release mode configuration
          if [ -f ".github/release-config.json" ]; then
            release_mode_enabled=$(jq -r '.releaseMode.enabled // false' .github/release-config.json)
            size_limit=$(jq -r '.releaseMode.relaxedRules.prSizeLimit // 300' .github/release-config.json)
          else
            release_mode_enabled="false"
            size_limit=300
          fi

          # Get PR stats
          PR_FILES=$(gh pr view ${{ github.event.pull_request.number }} --json files -q '.files[].path')
          PR_ADDITIONS=$(gh pr view ${{ github.event.pull_request.number }} --json additions -q '.additions')
          PR_DELETIONS=$(gh pr view ${{ github.event.pull_request.number }} --json deletions -q '.deletions')
          PR_CHANGES=$((PR_ADDITIONS + PR_DELETIONS))

          echo "PR has $PR_CHANGES changes ($PR_ADDITIONS additions, $PR_DELETIONS deletions)"

          # Only apply size check if no overrides and not in release mode
          if [[ "$has_override" == "true" || "$release_mode_enabled" == "true" ]]; then
            if [[ "$has_override" == "true" ]]; then
              echo "::notice::PR size check bypassed due to override label"
              echo "size_warning=false" >> $GITHUB_OUTPUT
              echo "size_bypassed=true" >> $GITHUB_OUTPUT
            elif [[ "$PR_CHANGES" -gt "$size_limit" ]]; then
              echo "::warning::This PR exceeds the relaxed limit of $size_limit lines during release mode. Consider breaking it down if possible."
              echo "size_warning=true" >> $GITHUB_OUTPUT
              echo "size_bypassed=false" >> $GITHUB_OUTPUT
            else
              echo "size_warning=false" >> $GITHUB_OUTPUT
              echo "size_bypassed=false" >> $GITHUB_OUTPUT
            fi
          elif [[ $PR_CHANGES -gt 300 ]]; then
            echo "::warning::This PR exceeds the recommended 300 lines limit. Please consider breaking it into smaller PRs."
            echo "size_warning=true" >> $GITHUB_OUTPUT
            echo "size_bypassed=false" >> $GITHUB_OUTPUT
          else
            echo "size_warning=false" >> $GITHUB_OUTPUT
            echo "size_bypassed=false" >> $GITHUB_OUTPUT
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Check PR age
        id: check-pr-age
        run: |
          # Check for override labels first
          has_override=${{ contains(github.event.pull_request.labels.*.name, 'extended-review') || contains(github.event.pull_request.labels.*.name, 'priority-release') || contains(github.event.pull_request.labels.*.name, 'emergency-override') }}

          # Check for release mode configuration
          if [ -f ".github/release-config.json" ]; then
            release_mode_enabled=$(jq -r '.releaseMode.enabled // false' .github/release-config.json)
            review_period=$(jq -r '.releaseMode.relaxedRules.reviewPeriod // 2' .github/release-config.json)
          else
            release_mode_enabled="false"
            review_period=2
          fi

          # Override for extended review
          if [[ "${{ contains(github.event.pull_request.labels.*.name, 'extended-review') }}" == "true" ]]; then
            review_period=7
          fi

          PR_CREATED_AT=$(gh pr view ${{ github.event.pull_request.number }} --json createdAt -q '.createdAt')
          PR_CREATED_TIMESTAMP=$(date -d "$PR_CREATED_AT" +%s)
          CURRENT_TIMESTAMP=$(date +%s)

          # Calculate PR age in days
          PR_AGE_SECONDS=$((CURRENT_TIMESTAMP - PR_CREATED_TIMESTAMP))
          PR_AGE_DAYS=$((PR_AGE_SECONDS / 86400))

          echo "PR age: $PR_AGE_DAYS days"

          # Check against appropriate review period
          if [[ "$has_override" == "true" || "$release_mode_enabled" == "true" ]]; then
            if [[ "$PR_AGE_DAYS" -gt "$review_period" ]]; then
              echo "::warning::This PR is older than $review_period days (extended period). Please consider resolving outstanding issues or closing it."
              echo "age_warning=true" >> $GITHUB_OUTPUT
            else
              echo "age_warning=false" >> $GITHUB_OUTPUT
            fi
          elif [[ $PR_AGE_DAYS -gt 2 ]]; then
            echo "::warning::This PR is older than 2 days. Please consider resolving outstanding issues or closing it."
            echo "age_warning=true" >> $GITHUB_OUTPUT
          else
            echo "age_warning=false" >> $GITHUB_OUTPUT
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Verify PR has description
        id: verify-description
        run: |
          PR_BODY=$(gh pr view ${{ github.event.pull_request.number }} --json body -q '.body')

          if [[ -z "$PR_BODY" || ${#PR_BODY} -lt 20 ]]; then
            echo "::warning::This PR has an insufficient description. Please add more details about the changes."
            echo "description_warning=true" >> $GITHUB_OUTPUT
          else
            echo "description_warning=false" >> $GITHUB_OUTPUT
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Check for tests
        id: check-tests
        run: |
          PR_FILES=$(gh pr view ${{ github.event.pull_request.number }} --json files -q '.files[].path')

          # Check if PR contains test files
          if ! echo "$PR_FILES" | grep -qE '(test|spec|__tests__|_test)\.(js|jsx|ts|tsx|py|go|rb|java|php)'; then
            # If no test files found, check if PR touches code that might need tests
            if echo "$PR_FILES" | grep -qE '\.(js|jsx|ts|tsx|py|go|rb|java|php)$'; then
              echo "::warning::This PR modifies code but doesn't include test updates. Please consider adding tests."
              echo "tests_warning=true" >> $GITHUB_OUTPUT
            fi
          else
            echo "tests_warning=false" >> $GITHUB_OUTPUT
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Comment PR issues
        if: |
          steps.verify-pr-size.outputs.size_warning == 'true' ||
          steps.check-pr-age.outputs.age_warning == 'true' ||
          steps.verify-description.outputs.description_warning == 'true' ||
          steps.check-tests.outputs.tests_warning == 'true'
        run: |
          COMMENT="## PR Check Results\n\n"

          if [[ "${{ steps.verify-pr-size.outputs.size_warning }}" == "true" ]]; then
            COMMENT+="⚠️ **Size Warning**: This PR exceeds the recommended 300 lines limit. Please consider breaking it into smaller PRs.\n\n"
          fi

          if [[ "${{ steps.check-pr-age.outputs.age_warning }}" == "true" ]]; then
            COMMENT+="⏱️ **Age Warning**: This PR is older than 2 days. Please consider resolving outstanding issues or closing it.\n\n"
          fi

          if [[ "${{ steps.verify-description.outputs.description_warning }}" == "true" ]]; then
            COMMENT+="📝 **Description Warning**: This PR has an insufficient description. Please add more details about the changes.\n\n"
          fi

          if [[ "${{ steps.check-tests.outputs.tests_warning }}" == "true" ]]; then
            COMMENT+="🧪 **Testing Warning**: This PR modifies code but doesn't include test updates. Please consider adding tests.\n\n"
          fi

          COMMENT+="\nFor more information, please see our [Development & PR Management Guide](../blob/main/docs/dev_pr_mgmt.md)."

          gh pr comment ${{ github.event.pull_request.number }} --body "$COMMENT"
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

## 🚀 Working with Complex Features and Teams

### Managing Larger Features

For features that cannot reasonably fit within 300 lines:

1. **Breakdown Strategy**:

   - Split larger features into smaller, independently deployable increments
   - Create a sequence of dependent PRs, each focused on one aspect
   - Use feature flags to hide unfinished functionality in production

2. **Documentation**:
   - Create a feature design document that outlines the breakdown
   - Reference the design document in each related PR
   - Track progress in an issue with a checklist of components

### Team Collaboration

For teams working on related features:

1. **Coordination Techniques**:

   - Hold brief daily standups to discuss branch status and merge plans
   - Use shared issue tracking to coordinate dependent changes
   - Designate a "merge coordinator" for complex features

2. **Preventing Conflicts**:
   - Merge to `main` frequently (at least daily)
   - Keep each team member's scope isolated when possible
   - Use feature toggles to integrate incomplete work safely

### Common Edge Cases

1. **Immediate Hotfix Needed**:

   - Create `hotfix/description` branch directly from `main`
   - Get expedited review (tag team leads)
   - Apply `auto-merge` label with highest priority

2. **Dependent PRs**:
   - Create PRs in logical order
   - Use "Draft PR" status for PRs that depend on others
   - Clearly mark dependencies in PR description

---

## 🔐 Handling Urgent Security Fixes

Security vulnerabilities require special treatment with a focus on:

1. Expedited review and deployment
2. Limited visibility until patched
3. Proper documentation for compliance
4. Careful coordination of disclosure

### Security Fix Fast Path

**File:** `.github/workflows/security-fix-path.yml`

```yaml
name: Security Fix Fast Path

on:
  pull_request:
    types: [opened, reopened, synchronize, labeled]
  workflow_dispatch:
    inputs:
      prNumber:
        description: "PR Number for security fix"
        required: true
        type: number

jobs:
  security-fast-path:
    runs-on: ubuntu-latest
    if: |
      (github.event_name == 'workflow_dispatch') ||
      (contains(github.event.pull_request.labels.*.name, 'security-fix'))
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set PR number
        id: set-pr
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "pr_number=${{ github.event.inputs.prNumber }}" >> $GITHUB_OUTPUT
          else
            echo "pr_number=${{ github.event.pull_request.number }}" >> $GITHUB_OUTPUT
          fi

      - name: Notify security team
        run: |
          PR_URL="https://github.com/${{ github.repository }}/pull/${{ steps.set-pr.outputs.pr_number }}"

          # Create a private issue in the security repository
          gh issue create \
            --title "⚠️ Security Fix - Needs Review PR #${{ steps.set-pr.outputs.pr_number }}" \
            --body "A security fix has been submitted and needs immediate review.

            **PR:** $PR_URL

            @security-team please review ASAP.

            DO NOT DISCUSS DETAILS IN PUBLIC CHANNELS." \
            --repo "${{ github.repository_owner }}/security-alerts" \
            --label "critical,security,needs-review"
        env:
          GITHUB_TOKEN: ${{ secrets.SECURITY_REPO_TOKEN }}

      - name: Fast-track PR approval
        run: |
          # Apply security labels and trigger expedited review
          gh pr edit ${{ steps.set-pr.outputs.pr_number }} \
            --add-label "security-fix" \
            --add-label "priority-critical"

          # Tag security team reviewers
          gh pr edit ${{ steps.set-pr.outputs.pr_number }} \
            --add-reviewer "${{ github.repository_owner }}/security-reviewers"

          # Request review from specific security team members
          COMMENT="## 🔐 Security Fix Fast Path Activated

          This PR contains a security fix and has been placed on the security fast path.

          **@security-team** Required reviewers have been notified. Please review ASAP.

          **Approvals needed:** 2 security team members

          **Next steps after approval:**
          1. 🔄 PR will be auto-merged once approved
          2. 🚀 An expedited deployment will be triggered
          3. 📋 CVE/security advisory will be created automatically"

          gh pr comment ${{ steps.set-pr.outputs.pr_number }} --body "$COMMENT"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up expedited CI
        run: |
          # For security PRs, we run a more targeted CI process
          # Configure the security-specific CI pipeline
          gh workflow run expedited-security-ci.yml -f pr=${{ steps.set-pr.outputs.pr_number }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  security-auto-merge:
    runs-on: ubuntu-latest
    if: |
      contains(github.event.pull_request.labels.*.name, 'security-fix') &&
      github.event.pull_request.draft == false
    steps:
      - name: Set up auto-merge with stricter review requirements
        uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          MERGE_METHOD: "squash"
          MERGE_LABELS: "security-fix,!do-not-merge"
          MERGE_REMOVE_LABELS: "security-fix"
          MERGE_COMMIT_MESSAGE: "Security fix: ${{ github.event.pull_request.title }}"
          MERGE_RETRIES: "10"
          MERGE_RETRY_SLEEP: "60000"
          MERGE_REQUIRED_APPROVING_REVIEW_COUNT: "2"
          UPDATE_METHOD: "rebase"
```

### Security Fix Guidelines

To submit and process security fixes:

1. **For the submitter**:

   ```bash
   # Create a security fix branch with minimal description
   git checkout -b security-fix-1234

   # Make changes - keep minimal and focused

   # Push to remote with limited information
   git push -u origin security-fix-1234

   # Create PR with security-fix label
   gh pr create --title "Security fix" --body "Details provided privately" --label security-fix
   ```

2. **For reviewers**:

   - Respond to security team notifications immediately
   - Use private channels for discussion, not PR comments
   - Perform thorough review focusing on:
     - Complete vulnerability resolution
     - No new security issues introduced
     - Minimal scope focused on the fix
   - Provide approval when satisfied

3. **Post-merge process**:

   **File:** `.github/workflows/security-post-merge.yml`

   ```yaml
   name: Security Fix Post-Merge

   on:
     pull_request:
       types: [closed]

   jobs:
     security-post-processing:
       runs-on: ubuntu-latest
       if: |
         github.event.pull_request.merged == true &&
         contains(github.event.pull_request.labels.*.name, 'security-fix')
       steps:
         - name: Checkout code
           uses: actions/checkout@v4

         - name: Create security advisory draft
           id: create-advisory
           run: |
             # Create a draft advisory
             ADVISORY_ID=$(gh api \
               --method POST \
               -H "Accept: application/vnd.github+json" \
               -H "X-GitHub-Api-Version: 2022-11-28" \
               /repos/${{ github.repository }}/security-advisories \
               -f summary="Security fix merged - pending disclosure" \
               -f description="A security fix has been deployed. Full details pending disclosure process." \
               -f severity="high" \
               -f cve_id="" \
               -f vulnerabilities[0][package][ecosystem]="npm" \
               -f vulnerabilities[0][package][name]="${{ github.repository }}" \
               -f vulnerabilities[0][vulnerable_version_range]="< $(git describe --tags --abbrev=0)" \
               -f vulnerabilities[0][patched_version]="pending" \
               -f state="draft" | jq -r '.id')

             echo "advisory_id=$ADVISORY_ID" >> $GITHUB_OUTPUT
           env:
             GITHUB_TOKEN: ${{ secrets.SECURITY_ADVISORY_TOKEN }}

         - name: Expedite deployment
           run: |
             # Trigger emergency deployment workflow
             gh workflow run emergency-deploy.yml -f reason="Security fix" -f pr="${{ github.event.pull_request.number }}"
           env:
             GITHUB_TOKEN: ${{ secrets.WORKFLOW_DISPATCH_TOKEN }}

         - name: Notify security team
           run: |
             COMMENT="## 🔒 Security Fix Deployed

             **PR:** #${{ github.event.pull_request.number }}

             **Advisory:** Created draft (ID: ${{ steps.create-advisory.outputs.advisory_id }})

             **Next steps:**
             1. Complete security advisory details
             2. Verify deployment and fix effectiveness
             3. Plan coordinated disclosure"

             # Comment in the private security repository
             gh issue comment $(gh issue list --repo "${{ github.repository_owner }}/security-alerts" \
               --search "Security Fix - Needs Review PR #${{ github.event.pull_request.number }}" \
               --state all --json number -q '.[0].number') \
               --body "$COMMENT" \
               --repo "${{ github.repository_owner }}/security-alerts"
           env:
             GITHUB_TOKEN: ${{ secrets.SECURITY_REPO_TOKEN }}
   ```

---

## 🔐 Workflow Security and Secrets Management

Secure handling of tokens and credentials is critical for CI/CD security. For comprehensive guidance on this topic, refer to the dedicated `docs/secrets_management_guide.md` document.

Key principles to follow:

1. **Use the built-in GITHUB_TOKEN when possible**:

   ```yaml
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

2. **Set minimum required permissions**:

   ```yaml
   permissions:
     contents: read
     issues: write
     pull-requests: write
   ```

3. **Avoid exposing secrets in logs**:

   ```yaml
   # DON'T do this
   run: echo "My secret is ${{ secrets.MY_SECRET }}"

   # DO use environment variables instead
   env:
     MY_SECRET: ${{ secrets.MY_SECRET }}
   run: ./use-secret-safely.sh
   ```

4. **Use secret scanning** to detect accidental secret commits:
   - See the `gitleaks.yml` workflow for implementation details

For full security hardening guidance, see the dedicated guide in `docs/secrets_management_guide.md`.

---
