# Secrets Management and Token Safety

This guide outlines best practices for managing secrets and tokens in your GitHub Actions workflows to prevent accidental exposure and secure your CI/CD pipeline.

## Core Principles

1. **Never expose secrets in logs**: GitHub automatically redacts secrets from logs, but inline scripts and error messages can still leak them
2. **Use least privilege tokens**: Always scope tokens to the minimum required permissions
3. **Rotate secrets regularly**: Set up automatic rotation for sensitive credentials
4. **Audit secret usage**: Regularly review which workflows use which secrets

## OpenID Connect (OIDC) Integration

GitHub Actions supports OpenID Connect (OIDC), which provides temporary, automatically-rotated credentials:

```yaml
jobs:
  deploy-to-cloud:
    # For AWS
    permissions:
      id-token: write # Required for OIDC
      contents: read # Required to check out code

    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/my-github-actions-role
          aws-region: us-east-1
```

### OIDC Setup for Cloud Providers

1. **AWS**: [AWS OIDC Setup Guide](https://github.com/aws-actions/configure-aws-credentials)
2. **Azure**: [Azure OIDC Setup Guide](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
3. **GCP**: [GCP OIDC Setup Guide](https://github.com/google-github-actions/auth)

## Securing GitHub Tokens

The default `GITHUB_TOKEN` has varying permissions based on the event trigger:

```yaml
# Restrict token permissions to the minimum required
permissions:
  contents: read
  issues: write # Only if needed
  pull-requests: write # Only if needed
  # Don't add unnecessary permissions
```

### Token Security Tips

1. **Never use Personal Access Tokens (PATs)** when `GITHUB_TOKEN` can do the job
2. **Create dedicated Machine Users/Bot accounts** for system automation tasks
3. **Use short-lived tokens** with automatic expiration
4. **Use environment secrets** for deployment-specific credentials

## Secret Scanning with Pre-commit Hooks

Set up pre-commit hooks to prevent secrets from being committed:

```yaml
name: Secret Scanning

on: [pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }} # Optional
```

## Running Secret Scans in CI/CD

```yaml
name: Dependency and Secret Scan

on:
  pull_request:
    paths:
      - "package*.json"
      - "requirements*.txt"
      - "Pipfile*"
      - "**/*.lock"

jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: TruffleHog OSS
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          extra_args: --debug --only-verified
```

## Vault Integration

For more complex secret management, consider HashiCorp Vault:

```yaml
jobs:
  integrate-vault:
    runs-on: ubuntu-latest
    steps:
      - name: Import Secrets
        uses: hashicorp/vault-action@v2
        with:
          url: https://vault.example.com
          tlsSkipVerify: false
          method: approle
          roleId: ${{ secrets.VAULT_ROLE_ID }}
          secretId: ${{ secrets.VAULT_SECRET_ID }}
          secrets: |
            secret/data/ci/aws accessKey | AWS_ACCESS_KEY_ID ;
            secret/data/ci/aws secretKey | AWS_SECRET_ACCESS_KEY

      - name: Use secrets
        run: |
          # Now AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are available as env vars
          aws s3 ls
```

## Key Rotation Strategies

1. **Scheduled rotation workflow**:

```yaml
name: Rotate Secrets

on:
  schedule:
    - cron: "0 0 1 * *" # Midnight on the 1st of every month
  workflow_dispatch: {} # Allow manual triggers

jobs:
  rotate-keys:
    runs-on: ubuntu-latest
    steps:
      - name: Rotate API Keys
        run: |
          # Script to rotate API keys and update GitHub secrets
          NEW_KEY=$(curl -X POST https://api.service.com/rotate-key)

          # Update GitHub secret
          gh secret set API_KEY -b "$NEW_KEY" -r ${{ github.repository }}
    env:
      GITHUB_TOKEN: ${{ secrets.ADMIN_TOKEN }} # Needs admin:org scope
```

## Security Audit Workflow

Add a regular security audit to check for secret usage:

```yaml
name: Security Audit

on:
  schedule:
    - cron: "0 0 * * 0" # Weekly on Sundays
  workflow_dispatch: {}

jobs:
  audit-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Audit secret usage
        run: |
          # Find all workflow files
          WORKFLOWS=$(find .github/workflows -name "*.yml" -o -name "*.yaml")

          # Grep for secrets usage
          echo "## Secret Usage Audit" > secret_audit.md
          echo "" >> secret_audit.md
          echo "| Workflow | Secrets Used |" >> secret_audit.md
          echo "|----------|--------------|" >> secret_audit.md

          for workflow in $WORKFLOWS; do
            SECRETS=$(grep -o "secrets\.[A-Za-z0-9_-]*" $workflow | sort | uniq | tr '\n' ',' | sed 's/,$//' | sed 's/secrets\.//g')
            if [ ! -z "$SECRETS" ]; then
              echo "| $workflow | $SECRETS |" >> secret_audit.md
            fi
          done

          # Create or update issue with findings
          gh issue create --title "Secret Usage Audit - $(date +%Y-%m-%d)" --body-file secret_audit.md --label "security,audit"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Best Practices Checklist

- [ ] Replace hardcoded secrets with environment variable references
- [ ] Use OIDC where possible instead of long-lived credentials
- [ ] Implement secret scanning in the CI pipeline
- [ ] Configure minimum required permissions for GitHub tokens
- [ ] Set up regular secret rotation
- [ ] Audit secret usage regularly
- [ ] Use Vault for complex secret management
- [ ] Implement branch protection rules to prevent force pushes that might leak secrets
- [ ] Use environment secrets for deployment-specific credentials

By implementing these practices, you'll significantly reduce the risk of secret exposure in your GitHub Actions workflows.
