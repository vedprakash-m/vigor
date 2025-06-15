#!/bin/bash
# Comprehensive Local Validation Script for Vigor Project
# This script validates your local codebase against CI/CD requirements before pushing to GitHub

set -e  # Exit on first error

echo "🔍 Running comprehensive local validation for Vigor project..."

# Variables to control execution
PRE_COMMIT_MODE=false
SKIP_TESTS=false
SKIP_AZURE=true
SKIP_E2E=false

# Parse command-line arguments
parse_arguments() {
  for arg in "$@"; do
    case $arg in
      --pre-commit)
        PRE_COMMIT_MODE=true
        SKIP_TESTS=true
        SKIP_AZURE=true
        SKIP_E2E=true
        ;;
      --skip-tests)
        SKIP_TESTS=true
        ;;
      --skip-e2e)
        SKIP_E2E=true
        ;;
      --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --pre-commit     Run in pre-commit mode (skips tests, Azure validation, and E2E tests)"
        echo "  --skip-tests     Skip running tests (faster)"
        echo "  --skip-e2e       Skip end-to-end tests (faster)"
        echo "  --help           Display this help message"
        exit 0
        ;;
    esac
  done
}

# Check workflow files for common issues
validate_workflows() {
  echo "🔍 Validating GitHub Actions workflows..."

  # Check for required workflows
  required_workflows=(
    ".github/workflows/backend-ci.yml"
    ".github/workflows/frontend-ci.yml"
    ".github/workflows/e2e-tests.yml"
    ".github/workflows/deploy.yml"
    ".github/workflows/secret-scan.yml"
  )

  for workflow in "${required_workflows[@]}"; do
    if [ ! -f "$workflow" ]; then
      echo "❌ Required workflow missing: $workflow"
      exit 1
    fi
  done

  # Validate workflow syntax
  echo "   Validating workflow YAML syntax..."
  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    if [ -f "$workflow" ]; then
      echo "   Checking $workflow..."

      # Check for YAML document start marker
      if ! head -1 "$workflow" | grep -q "^---"; then
        echo "❌ $workflow missing YAML document start marker (---)"
        exit 1
      fi

      # Check for permissions block
      if ! grep -q "permissions:" "$workflow"; then
        echo "❌ $workflow missing permissions block"
        exit 1
      fi

      # Validate YAML syntax
      if command -v yamllint &> /dev/null; then
        yamllint "$workflow" || { echo "❌ $workflow has YAML syntax errors"; exit 1; }
      fi

      # Check for deprecated actions
      if grep -q "actions/upload-artifact@v3" "$workflow"; then
        echo "❌ $workflow uses deprecated upload-artifact@v3"
        exit 1
      fi

      if grep -q "actions/setup-python@v4" "$workflow"; then
        echo "❌ $workflow uses deprecated setup-python@v4"
        exit 1
      fi
    fi
  done

  # Check for artifact path consistency
  echo "   Checking artifact path consistency..."
  if [ -f ".github/workflows/backend-ci.yml" ]; then
    if grep -q "backend/" .github/workflows/backend-ci.yml | grep -q "path:"; then
      echo "❌ Backend CI workflow has incorrect artifact paths (should be relative to working-directory)"
      exit 1
    fi
  fi

  echo "✅ All workflows validated successfully"
}

# Enhanced secrets detection
enhanced_secrets_check() {
  echo "🔍 Enhanced secrets detection..."

  # Check for common secret patterns
  secret_patterns=(
    "password\s*=\s*['\"][^'\"]{8,}"
    "secret\s*=\s*['\"][^'\"]{16,}"
    "key\s*=\s*['\"][^'\"]{16,}"
    "token\s*=\s*['\"][^'\"]{16,}"
    "api[_-]?key\s*=\s*['\"][^'\"]{16,}"
    "AKIA[0-9A-Z]{16}"  # AWS Access Key
    "sk-[a-zA-Z0-9]{48}"  # OpenAI API key
  )

  for pattern in "${secret_patterns[@]}"; do
    if grep -r -E "$pattern" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=venv --exclude="*.log"; then
      echo "⚠️ Potential secret detected with pattern: $pattern"
      echo "   Please review and use environment variables or secret management"
    fi
  done
}

# Validate Docker configuration
validate_docker() {
  echo "🐳 Validating Docker configuration..."

  if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found"
    exit 1
  fi

  # Check Docker Compose syntax
  if command -v docker-compose &> /dev/null; then
    docker-compose config > /dev/null || { echo "❌ docker-compose.yml has syntax errors"; exit 1; }
  elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    docker compose config > /dev/null || { echo "❌ docker-compose.yml has syntax errors"; exit 1; }
  fi

  echo "✅ Docker configuration validated"
}
check_required_tools() {
  echo "📋 Checking required tools..."

  # Check for Azure CLI
  if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found! Please install it: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
  fi

  # Check for Node.js
  if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found! Please install it: https://nodejs.org/"
    exit 1
  fi

  # Check for Python
  if ! command -v python3 &> /dev/null; then
    echo "❌ Python not found! Please install Python 3.12+"
    exit 1
  fi

  # Check for actionlint and yamllint (optional)
  if ! command -v actionlint &> /dev/null; then
    echo "⚠️ actionlint not found. Workflow validation will be limited. Consider installing it."
  fi

  if ! command -v yamllint &> /dev/null; then
    echo "⚠️ yamllint not found. Workflow validation will be limited. Consider installing it."
  fi

  echo "✅ Required tools check passed!"
}

# Validate Bicep infrastructure
validate_infrastructure() {
  echo "🏗️ Validating Bicep infrastructure..."

  # Validate main Bicep template
  echo "   Validating main.bicep..."
  az bicep build --file infrastructure/bicep/main.bicep

  # Optional: More detailed validation could be added, e.g., az deployment group validate
  # This would require a resource group to validate against

  echo "✅ Bicep infrastructure validation passed!"
}

# Validate backend code
validate_backend() {
  echo "🐍 Validating backend code..."

  cd backend

  # Create or activate virtual environment if it doesn't exist
  if [ ! -d "venv" ]; then
    echo "   Creating virtual environment..."
    python3 -m venv venv
  fi

  # Activate virtual environment
  echo "   Activating virtual environment..."
  source venv/bin/activate

  # Install dependencies
  echo "   Installing dependencies..."
  pip install -r requirements.txt
  pip install black isort flake8 bandit mypy pytest pytest-cov safety

  # Run code formatting checks
  echo "   Checking code formatting with black..."
  black --check --diff . || { echo "❌ black formatting check failed"; exit 1; }

  # Run import sorting checks
  echo "   Checking import sorting with isort..."
  isort --check-only --diff . || { echo "❌ isort check failed"; exit 1; }

  # Run linting
  echo "   Running flake8 linting..."
  flake8 . || { echo "⚠️ flake8 found issues. Consider fixing them."; }

  # Run security checks
  echo "   Running security scan with bandit..."
  if [ -f ".bandit" ]; then
    bandit -c .bandit -r . -f json -o bandit_report.json
    # Only fail on high severity issues (matching CI)
    bandit -c .bandit -r . --severity-level high || { echo "❌ bandit found high security issues"; exit 1; }
  else
    bandit -r . --severity-level high || { echo "❌ bandit found high security issues"; exit 1; }
  fi

  # Run type checking
  echo "   Running mypy type checking..."
  mypy . --config-file=mypy.ini || { echo "❌ mypy type checking failed"; exit 1; }

  # Run dependency security check
  echo "   Checking dependencies with safety..."
  safety check --output json > safety_report.json || { echo "⚠️ safety found security vulnerabilities"; }

  # Run tests
  if [ "$SKIP_TESTS" = false ]; then
    echo "   Running tests with pytest..."
    pytest --cov=. --cov-report=xml --cov-report=html -v || { echo "❌ pytest tests failed"; exit 1; }
  else
    echo "   Skipping tests as per configuration"
  fi

  # Compilation check
  echo "   Checking Python compilation..."
  python -m compileall .

  # Deactivate virtual environment
  deactivate

  cd ..

  echo "✅ Backend validation passed!"
}

# Validate frontend code
validate_frontend() {
  echo "🌐 Validating frontend code..."

  if [ ! -d "frontend" ]; then
    echo "❌ Frontend directory not found! Skipping frontend validation."
    return 1
  fi

  cd frontend

  # Install dependencies
  echo "   Installing dependencies..."
  npm ci || {
    echo "⚠️ npm ci had issues. This might be due to package-lock.json sync issues."
    echo "   Consider running: npm install && git add package-lock.json"

    if [ "$PRE_COMMIT_MODE" = false ]; then
      echo "❌ Frontend dependency installation failed, fix before proceeding"
      cd ..
      return 1
    fi
  }

  # Run linting with detailed output
  echo "   Running ESLint..."
  if ! npm run lint > /tmp/eslint_output.txt 2>&1; then
    echo "❌ ESLint failed with the following issues:"
    cat /tmp/eslint_output.txt

    if [ "$PRE_COMMIT_MODE" = false ]; then
      cd ..
      return 1
    fi
  fi

  # Run tests
  if [ "$SKIP_TESTS" = false ]; then
    echo "   Running tests with coverage..."
    if ! npm test -- --coverage > /tmp/test_output.txt 2>&1; then
      echo "❌ Frontend tests failed:"
      cat /tmp/test_output.txt
      cd ..
      return 1
    else
      echo "   Test coverage report generated in frontend/coverage/"
    fi
  else
    echo "   Skipping tests as per configuration"
  fi

  # Build frontend
  if [ "$PRE_COMMIT_MODE" = false ]; then
    echo "   Building frontend..."
    if ! npm run build > /tmp/build_output.txt 2>&1; then
      echo "❌ Frontend build failed:"
      cat /tmp/build_output.txt
      cd ..
      return 1
    else
      echo "   Frontend build successful!"
      echo "   Output available in frontend/dist/"
    fi
  else
    echo "   Skipping frontend build in pre-commit mode"
  fi

  cd ..

  echo "✅ Frontend validation passed!"
  return 0
}

# Validate deployment scripts
validate_deployment_scripts() {
  echo "🚀 Validating deployment scripts..."

  # Check if health check script exists and is executable
  if [ -f "scripts/health-check.sh" ]; then
    if [ ! -x "scripts/health-check.sh" ]; then
      chmod +x scripts/health-check.sh
      echo "   Made health-check.sh executable"
    fi
  else
    echo "❌ health-check.sh script missing!"
  fi

  # Check if smoke test script exists and is executable
  if [ -f "scripts/run-smoke-tests.sh" ]; then
    if [ ! -x "scripts/run-smoke-tests.sh" ]; then
      chmod +x scripts/run-smoke-tests.sh
      echo "   Made run-smoke-tests.sh executable"
    fi
  else
    echo "❌ run-smoke-tests.sh script missing!"
  fi

  echo "✅ Deployment scripts validation completed!"
}

# Validate for secrets in codebase
validate_secrets() {
  echo "🔒 Checking for secrets in codebase..."

  # Create temp directory for validation results
  mkdir -p /tmp/security-validation

  # Check if gitleaks is installed
  if ! command -v gitleaks &> /dev/null; then
    echo "⚠️ gitleaks not found. Secrets validation will be limited."
    echo "   Consider installing it with: brew install gitleaks"

    # Fallback to grep-based secret detection
    echo "   Running basic grep-based secret detection..."

    # Define common patterns for secrets
    SECRET_PATTERNS=(
      "API[_-]KEY[=\"']"
      "SECRET[_-]KEY[=\"']"
      "password[=\"']"
      "ACCESS[_-]TOKEN[=\"']"
      "Bearer [A-Za-z0-9+/=]+"
      "[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+" # JWT pattern
      "-----BEGIN RSA PRIVATE KEY-----"
      "aws_access_key_id"
      "AKIA[A-Z0-9]{16}"
    )

    # Search for patterns
    echo "   Searching for common secret patterns..."
    FOUND_SECRETS=false

    for pattern in "${SECRET_PATTERNS[@]}"; do
      GREP_RESULT=$(grep -r --include="*.{js,ts,py,sh,json,yml,yaml}" "$pattern" . 2>/dev/null)
      if [ ! -z "$GREP_RESULT" ]; then
        echo "⚠️ Potential secret found with pattern: $pattern"
        echo "$GREP_RESULT" > /tmp/security-validation/grep_secrets.txt
        echo "   Review file: /tmp/security-validation/grep_secrets.txt"
        FOUND_SECRETS=true
      fi
    done

    if [ "$FOUND_SECRETS" = true ]; then
      echo "⚠️ Potential secrets found in the codebase!"
      echo "   Please review and remove any sensitive information before committing"
      if [ "$PRE_COMMIT_MODE" = false ]; then
        return 1
      fi
    fi
  else
    echo "   Running comprehensive gitleaks scan..."
    if ! gitleaks detect --no-git --report-path /tmp/security-validation/gitleaks_report.json; then
      echo "⚠️ gitleaks found potential secrets in the codebase!"
      echo "   Report saved to: /tmp/security-validation/gitleaks_report.json"
      echo "   Please review and remove any sensitive information before committing"
      if [ "$PRE_COMMIT_MODE" = false ]; then
        return 1
      fi
    else
      echo "   No secrets detected by gitleaks"
    fi
  fi

  # Check for .env files with real credentials
  echo "   Checking for .env files..."
  ENV_FILES=$(find . -name ".env*" -not -name ".env.example" -not -name ".env.template")
  if [ ! -z "$ENV_FILES" ]; then
    echo "⚠️ Found potentially sensitive .env files:"
    echo "$ENV_FILES"
    echo "   Ensure these files are in .gitignore and don't contain real credentials"
  fi

  echo "✅ Secrets validation completed!"
  return 0
}

# Validate end-to-end tests
validate_e2e_tests() {
  if [ "$SKIP_E2E" = true ]; then
    echo "🔄 Skipping end-to-end tests as per configuration"
    return 0
  fi

  echo "🧪 Running end-to-end tests..."

  # Check for playwright or cypress
  if [ -d "frontend/e2e" ] || [ -d "e2e" ]; then
    # Determine the e2e directory
    E2E_DIR="e2e"
    if [ -d "frontend/e2e" ]; then
      E2E_DIR="frontend/e2e"
    fi

    echo "   Found E2E test directory: $E2E_DIR"

    # Handle Playwright
    if [ -f "$E2E_DIR/playwright.config.ts" ] || [ -f "$E2E_DIR/playwright.config.js" ]; then
      echo "   Detected Playwright E2E tests"

      if command -v npx &> /dev/null; then
        echo "   Running Playwright tests..."
        cd $E2E_DIR

        if ! npx playwright test; then
          echo "❌ Playwright E2E tests failed!"
          cd - > /dev/null
          return 1
        fi

        cd - > /dev/null
      else
        echo "❌ npx not found. Cannot run Playwright tests!"
        return 1
      fi
    # Handle Cypress
    elif [ -f "$E2E_DIR/cypress.config.ts" ] || [ -f "$E2E_DIR/cypress.config.js" ]; then
      echo "   Detected Cypress E2E tests"

      if command -v npx &> /dev/null; then
        echo "   Running Cypress tests..."
        cd $E2E_DIR

        if ! npx cypress run; then
          echo "❌ Cypress E2E tests failed!"
          cd - > /dev/null
          return 1
        fi

        cd - > /dev/null
      else
        echo "❌ npx not found. Cannot run Cypress tests!"
        return 1
      fi
    else
      echo "❌ No recognized E2E test configuration found in $E2E_DIR"
      return 1
    fi
  else
    echo "⚠️ No end-to-end test directory found"
    echo "   Consider adding end-to-end tests under frontend/e2e/ or e2e/"
    return 0
  fi

  echo "✅ End-to-end tests passed!"
  return 0
}

# Validate Azure deployment (if credentials are available)
validate_azure_deployment() {
  echo "☁️ Validating Azure deployment..."

  # Check if logged into Azure
  az account show &> /dev/null
  if [ $? -ne 0 ]; then
    echo "⚠️ Not logged into Azure. Deployment validation will be skipped."
    echo "   Login with 'az login' to enable deployment validation"
    return 0
  fi

  # Get resource group for validation
  local RESOURCE_GROUP=""
  read -p "Enter resource group name for deployment validation (or leave empty to skip): " RESOURCE_GROUP

  if [ -z "$RESOURCE_GROUP" ]; then
    echo "⚠️ Resource group not provided. Skipping deployment validation."
    return 0
  fi

  # Validate Bicep deployment
  echo "   Validating Bicep deployment against resource group: $RESOURCE_GROUP"
  az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infrastructure/bicep/main.bicep \
    --parameters @infrastructure/bicep/parameters.dev.json \
    --no-prompt \
    --query "properties.provisioningState" \
    --output tsv || {
      echo "❌ Azure deployment validation failed!"
      return 1
    }

  echo "✅ Azure deployment validation passed!"
  return 0
}

# Run end-to-end tests locally if available
run_e2e_tests() {
  echo "🧪 Running end-to-end tests..."

  # Check if Playwright is installed in frontend
  if [ -f "frontend/playwright.config.ts" ] || [ -f "frontend/playwright.config.js" ]; then
    cd frontend

    # Check if Playwright tests exist
    if [ -d "e2e" ] || [ -d "tests/e2e" ]; then
      echo "   Found Playwright tests, running..."

      # Install dependencies if needed
      if ! npm list | grep -q "playwright"; then
        echo "   Installing Playwright dependencies..."
        npx playwright install --with-deps chromium
      fi

      # Run the tests
      npm run test:e2e || {
        echo "❌ End-to-end tests failed";
        cd ..
        return 1
      }
    else
      echo "⚠️ No end-to-end tests found in frontend"
    fi

    cd ..
  else
    echo "⚠️ No Playwright configuration found, skipping E2E tests"
  fi

  echo "✅ End-to-end test validation completed!"
  return 0
}

# Run all validations
main() {
  local HAS_ERRORS=0

  echo "🚀 Starting comprehensive local validation for Vigor project..."
  echo "-------------------------------------------------------------"

  # Required tools check
  check_required_tools || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Infrastructure validation
  validate_infrastructure || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Backend validation
  validate_backend || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Frontend validation
  validate_frontend || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Workflow validation
  validate_workflows || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Enhanced secrets validation
  enhanced_secrets_check || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Docker validation
  validate_docker || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Secrets validation
  validate_secrets || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # E2E Test validation
  validate_e2e_tests || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # Deployment scripts validation
  validate_deployment_scripts || HAS_ERRORS=$((HAS_ERRORS + 1))
  echo "-------------------------------------------------------------"

  # End-to-end tests
  if [ "$SKIP_E2E" = false ]; then
    run_e2e_tests || HAS_ERRORS=$((HAS_ERRORS + 1))
    echo "-------------------------------------------------------------"
  else
    echo "⚠️ Skipping end-to-end tests as per configuration"
  fi

  # Ask for Azure deployment validation
  if [ "$SKIP_AZURE" = false ]; then
    read -p "Do you want to validate Azure deployment? (y/n): " RUN_AZURE
    if [[ "$RUN_AZURE" =~ ^[Yy]$ ]]; then
      echo "-------------------------------------------------------------"
      validate_azure_deployment || HAS_ERRORS=$((HAS_ERRORS + 1))
      echo "-------------------------------------------------------------"
    fi
  else
    echo "⚠️ Skipping Azure deployment validation as per configuration"
  fi

  if [ $HAS_ERRORS -eq 0 ]; then
    echo "🎉 All local validations passed! Your code should be ready for CI/CD."
  else
    echo "⚠️ Found $HAS_ERRORS validation issues that need to be addressed."
    echo "   Please fix the issues marked with ❌ above before committing."
  fi

  return $HAS_ERRORS
}

# Execute main function
parse_arguments "$@"
main
