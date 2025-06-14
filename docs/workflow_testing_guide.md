# GitHub Action Testing and Validation Guide

This document outlines strategies for testing, validating, and maintaining GitHub Action workflows to ensure they remain error-free and do not become development bottlenecks.

## 1. Workflow Health Check

We've implemented a **daily automated health check** (`workflow-health-check.yml`) that:

- Validates YAML syntax of all workflows
- Checks for broken references to actions or secrets
- Analyzes execution history and success rates
- Automatically creates/updates issues for problems
- Reports health status via Slack notifications

This proactive monitoring helps detect issues before they impact development.

## 2. Local Testing with `act`

The [act](https://github.com/nektos/act) tool allows you to run GitHub Actions locally:

```bash
# Install act
brew install act

# Run a specific workflow
act -j build

# Run with specific event
act pull_request -j pr-validation

# Use real GitHub token for testing
act -s GITHUB_TOKEN=ghp_your_token_here
```

## 3. Workflow Linting

Use these tools to check workflow syntax and best practices:

1. **GitHub Action Linter**:

```bash
npx yaml-lint .github/workflows/*.yml
```

2. **actionlint**:

```bash
# Install actionlint
brew install actionlint

# Run against all workflows
actionlint .github/workflows/*.yml
```

## 4. Gradual Rollout Strategy

When introducing new workflows or making significant changes:

1. **Start with workflow_dispatch only**:

   ```yaml
   on:
     workflow_dispatch: # Manual trigger only for testing
   ```

2. **Add paths-ignore to limit scope**:

   ```yaml
   on:
     pull_request:
       paths-ignore:
         - "docs/**"
         - "*.md"
   ```

3. **Use continue-on-error for new steps**:
   ```yaml
   steps:
     - name: New experimental step
       continue-on-error: true
       run: ./new-script.sh
   ```

## 5. Version Pinning

Always pin action versions to specific SHA commits rather than using floating tags:

```yaml
# AVOID (vulnerable to supply chain attacks)
- uses: actions/checkout@v4

# BETTER (pinned to specific version)
- uses: actions/checkout@v4.1.2

# BEST (pinned to specific SHA)
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608
```

## 6. Timeout Protection

Set job timeouts to prevent workflows from hanging indefinitely:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15 # Job will fail after 15 minutes
```

## 7. Monitoring and Analytics

1. **Execution Time Metrics**:

   - Our `workflow-health-check.yml` tracks execution time trends
   - Alert on significant increases in workflow duration

2. **Success Rate Tracking**:
   - Workflows with < 80% success rate are flagged for review
   - Track flaky tests and intermittent failures

## 8. Self-Healing Mechanisms

1. **Automatic Retry for Transient Failures**:

   ```yaml
   steps:
     - name: Flaky external API call
       id: api-call
       uses: nick-invision/retry-action@v2
       with:
         timeout_minutes: 10
         max_attempts: 3
         command: ./call-external-api.sh
   ```

2. **Circuit Breaker Pattern**:
   - Workflows can be automatically disabled if consistently failing
   - Prevents blocking team progress when external services are down

## 9. Bypass Mechanisms

Provide emergency bypass mechanisms for critical development scenarios:

1. **Override Labels**:

   - `workflow-exempt` label to skip certain checks
   - `priority-release` for expedited critical changes

2. **Workflow Path Filtering**:
   ```yaml
   on:
     pull_request:
       paths-ignore:
         - "docs/**" # Skip for documentation changes
   ```

## 10. Documentation and Review

- Document each workflow's purpose and failure modes
- Regularly review workflow runs for inefficiencies
- Collect team feedback on workflow pain points

By implementing these strategies, we ensure our GitHub Action workflows remain reliable, maintainable, and supportive rather than becoming development bottlenecks.
