# Local CI/CD Validation Guide

This document describes the comprehensive local validation process implemented for the Vigor project. By using these tools, you can ensure that your code will pass all CI/CD checks before pushing to GitHub, saving time and reducing failed builds.

## Overview

The local validation process mirrors the GitHub CI/CD pipeline as closely as possible, running the same checks that would be performed during continuous integration. This helps catch issues early in the development process.

## Available Tools

### Main Validation Script

The primary tool for local validation is the `local-ci-validate.sh` script located in the `scripts` directory. This script can be run with various options:

```bash
# Run full validation
./scripts/local-ci-validate.sh

# Run quick pre-commit validation
./scripts/local-ci-validate.sh --pre-commit

# Skip tests for faster validation
./scripts/local-ci-validate.sh --skip-tests

# Skip end-to-end tests
./scripts/local-ci-validate.sh --skip-e2e

# Show help
./scripts/local-ci-validate.sh --help
```

### Pre-Commit Mode

The `--pre-commit` flag activates a special mode optimized for git pre-commit hooks:

- **Faster execution**: Skips time-consuming tests, Azure validation, and E2E tests
- **Basic validations**: Runs essential checks like linting, formatting, and security scanning
- **Focus on commit-ready code**: Ensures code meets basic quality standards without blocking workflow
- **Exit on first error**: Fails fast to provide immediate feedback

This mode is specifically designed to provide quick feedback during the commit process while still catching common issues.

### Git Hooks Integration

To automatically validate your code before each commit, you can set up Git hooks using:

```bash
./scripts/setup-git-hooks.sh
```

This will install a pre-commit hook that:

1. Runs secret detection to prevent accidental credential leaks
2. Executes `local-ci-validate.sh` with the `--pre-commit` flag for lightweight validation
3. Blocks the commit if either check fails, with an option to bypass using `git commit --no-verify` (not recommended)

## What Gets Validated

The validation script checks the following aspects of your code:

### Full Validation Mode

When running without flags, the script performs comprehensive validation:

1. **Infrastructure**

   - Bicep template compilation
   - Optional: Azure deployment validation

2. **Backend**

   - Code formatting (black)
   - Import sorting (isort)
   - Linting (flake8)
   - Security scanning (bandit)
   - Type checking (mypy)
   - Dependency security (safety)
   - Tests (pytest)

3. **Frontend**

   - Linting (ESLint)
   - Tests (Jest)
   - Build process

4. **Security**

   - Secret detection (gitleaks)
   - Dependency vulnerabilities

5. **Workflows**

   - YAML validation
   - GitHub Actions best practices
   - Common workflow issues

6. **End-to-End Tests**
   - Playwright tests (if available)

### Pre-Commit Validation Mode

When running with `--pre-commit` flag, the script performs a lightweight subset:

1. **Backend**

   - Code formatting (black)
   - Import sorting (isort)
   - Linting (flake8)
   - Security scanning (bandit)
   - Type checking (mypy)
   - ~~Tests~~ (skipped in pre-commit mode)

2. **Frontend**

   - Linting (ESLint)
   - ~~Tests~~ (skipped in pre-commit mode)
   - ~~Build process~~ (skipped in pre-commit mode)

3. **Security**

   - Secret detection (gitleaks)
   - Dependency vulnerabilities

4. **Workflows**

   - YAML validation
   - GitHub Actions best practices

5. **Skipped in Pre-Commit Mode**
   - Azure deployment validation
   - End-to-End tests
   - Time-consuming test suites

## Best Practices

### Local Validation Workflow

1. **Use Git hooks for every commit**: Set up Git hooks with `./scripts/setup-git-hooks.sh` to ensure automatic validation during commits.
2. **Run full validation before PRs**: Run the complete validation suite before creating pull requests to catch all potential issues.
3. **Address all issues promptly**: Don't ignore validation failures - fix them before proceeding.
4. **Regular full validations**: While pre-commit hooks use a lightweight validation, periodically run the full validation to catch comprehensive issues.

### Pre-Commit Mode Usage

1. **Default for git hooks**: The pre-commit hook automatically uses the `--pre-commit` flag for efficiency.
2. **Manual pre-commit check**: Run `./scripts/local-ci-validate.sh --pre-commit` to manually perform a quick validation anytime.
3. **For quick feedback**: Use pre-commit mode during active development for faster feedback loops.
4. **Bypass with caution**: Only use `git commit --no-verify` when absolutely necessary, and follow up with full validation before pushing.

### Addressing Validation Issues

1. **Review error output**: Carefully examine reported issues from the validation script.
2. **Fix critical issues first**: If multiple issues are found, address security and breaking changes before style issues.
3. **Verify fixes**: After addressing issues, run the specific validation check again to confirm the fix.
4. **Continuous improvement**: Use validation results to improve coding practices and avoid similar issues in the future.

## Troubleshooting

### General Issues

If you encounter validation errors:

1. Review the error output carefully
2. Fix the issues in your code
3. Run the validation again
4. If you're stuck, check the project documentation or ask for help

### Pre-Commit Specific Issues

Common issues with pre-commit validation:

1. **Hook not running**: Verify hook installation with `ls -la .git/hooks/` and reinstall with `./scripts/setup-git-hooks.sh` if needed.
2. **Hook too slow**: If pre-commit validation is consistently too slow, consider customizing the checks or temporarily bypassing with `git commit --no-verify` for urgent commits.
3. **False positives**: If you encounter false positives in pre-commit mode, report them to improve the validation process.
4. **Missing dependencies**: If the pre-commit hook fails due to missing dependencies, make sure your development environment is properly set up.

### Bypassing Validation

In rare cases where bypassing the pre-commit hook is necessary:

```bash
# Bypass pre-commit validation (NOT RECOMMENDED for normal workflow)
git commit --no-verify -m "Your commit message"
```

⚠️ **Warning**: Always run full validation before pushing changes that bypassed pre-commit validation.

## Customizing Validation

### Modifying the Validation Script

If you need to customize the validation process for your specific workflow:

1. Open `scripts/local-ci-validate.sh` in your editor
2. Modify the existing checks or add new ones
3. Make sure to maintain compatibility with both normal and pre-commit modes
4. Document your changes for other team members

### Customizing Pre-Commit Behavior

To customize what happens during pre-commit validation:

1. Check the `PRE_COMMIT_MODE` section in `local-ci-validate.sh`
2. Modify the conditional logic for pre-commit mode to include/exclude specific checks
3. Update the git hook in `setup-git-hooks.sh` if you need to change the hook behavior

Example of adding a custom check to pre-commit mode only:

```bash
if [ "$PRE_COMMIT_MODE" = true ]; then
  echo "Running custom pre-commit check..."
  # Your custom check here
fi
```

## Adding New Checks

When adding new CI/CD checks to GitHub workflows:

1. Update the local validation script to include equivalent checks
2. Determine if the check should run in pre-commit mode based on:
   - Speed (slow checks should be excluded from pre-commit)
   - Criticality (critical checks should always be included)
   - Frequency of failures (frequently failing checks might be better in full validation)
3. Update the documentation to reflect the new checks

## Implementation Details

The pre-commit functionality is implemented through:

1. Flag detection in `local-ci-validate.sh` that activates pre-commit mode with appropriate skip flags
2. Integration in `.git/hooks/pre-commit` via the `setup-git-hooks.sh` script
3. Combined approach that runs both secret detection and lightweight validation

## Related Documentation

- [CI Optimization Guide](./ci_optimization_guide.md)
- [Workflow Testing Guide](./workflow_testing_guide.md)
- [Secrets Management Guide](./secrets_management_guide.md)

## Conclusion

The local validation system with pre-commit support provides a robust way to ensure code quality throughout the development process. By leveraging the `--pre-commit` flag, developers can enjoy:

- **Fast feedback**: Quick validations during the commit process
- **Early issue detection**: Catch problems before they enter the codebase
- **Streamlined workflow**: Balance between thorough validation and development speed
- **Consistent quality**: Maintain high standards across the entire project

Remember that the pre-commit validation is a complement to, not a replacement for, full validation. Use both tools appropriately to ensure the highest code quality with the least disruption to your development workflow.

- [CI Optimization Guide](ci_optimization_guide.md)
- [Workflow Testing Guide](workflow_testing_guide.md)
- [Secrets Management Guide](secrets_management_guide.md)
