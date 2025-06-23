#!/bin/bash
# Docker-based CI/CD Validation Script
# Runs the EXACT SAME commands as the GitHub Actions pipeline for perfect parity

set -e

echo "🐳 Docker CI/CD Validation - Perfect Parity Mode"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed or not available"
    exit 1
fi

print_success "Docker is available"

# Build the validation image
print_step "Building CI/CD validation Docker image..."
docker build -f Dockerfile.validation -t vigor-ci-validation . || {
    print_error "Failed to build Docker validation image"
    exit 1
}

print_success "CI/CD validation image built successfully"

# Run the exact same quality checks as CI/CD pipeline
print_step "Running CI/CD quality checks in Docker container..."

# Create a script that runs inside the container
cat > /tmp/ci-validation-script.sh << 'EOF'
#!/bin/bash
set -e

echo "🔧 Running CI/CD Quality Checks (Perfect Parity)"
echo "================================================"

# Backend checks (EXACT SAME as CI/CD pipeline)
echo "🔄 Backend linting & formatting"
cd /app/backend

# Step 1: Black formatting check (EXACT match to CI/CD)
echo "  → Running black --check ."
if ! black --check .; then
    echo "❌ Black formatting failed - this is exactly what CI/CD detected!"
    exit 1
fi
echo "✅ Black formatting passed"

# Step 2: isort import sorting check (EXACT match to CI/CD)
echo "  → Running isort --check-only ."
if ! isort --check-only .; then
    echo "❌ isort import sorting failed - this is exactly what CI/CD detected!"
    exit 1
fi
echo "✅ isort import sorting passed"

# Step 3: Ruff linting (EXACT match to CI/CD)
echo "  → Running ruff check ."
if ! ruff check .; then
    echo "❌ Ruff linting failed"
    exit 1
fi
echo "✅ Ruff linting passed"

# Step 4: MyPy type checking (EXACT match to CI/CD)
echo "  → Running mypy ."
if ! mypy .; then
    echo "❌ MyPy type checking failed"
    exit 1
fi
echo "✅ MyPy type checking passed"

# Step 5: Security scans (EXACT match to CI/CD)
echo "  → Running bandit security scan"
bandit -r . -f json -o bandit_report.json || true
echo "✅ Bandit security scan completed"

echo "  → Running safety vulnerability check"
if ! safety check; then
    echo "❌ Safety found vulnerabilities"
    exit 1
fi
echo "✅ Safety vulnerability check passed"

# Step 6: Backend tests (EXACT match to CI/CD)
echo "  → Running pytest with coverage"
if ! pytest -v --cov=. --cov-fail-under=50 --cov-report=term-missing; then
    echo "❌ Backend tests failed or coverage below 50%"
    exit 1
fi
echo "✅ Backend tests passed with adequate coverage"

# Frontend checks (EXACT SAME as CI/CD pipeline)
echo "🔄 Frontend linting & type checking"
cd /app/frontend

# Step 7: Frontend linting (EXACT match to CI/CD)
echo "  → Running npm run lint"
if ! npm run lint; then
    echo "❌ Frontend linting failed"
    exit 1
fi
echo "✅ Frontend linting passed"

# Step 8: Frontend type checking (EXACT match to CI/CD)
echo "  → Running npm run type-check"
if ! npm run type-check; then
    echo "❌ Frontend TypeScript compilation failed"
    exit 1
fi
echo "✅ Frontend type checking passed"

# Step 9: Frontend tests (EXACT match to CI/CD)
echo "  → Running npm test with coverage"
if ! npm test -- --coverage --watchAll=false; then
    echo "❌ Frontend tests failed"
    exit 1
fi
echo "✅ Frontend tests passed"

# Step 10: Frontend build verification (EXACT match to CI/CD)
echo "  → Running npm run build"
if ! npm run build; then
    echo "❌ Frontend build failed"
    exit 1
fi

# Verify build output exists (like CI/CD does)
if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
    echo "✅ Frontend build completed successfully"
    ls -la dist/
else
    echo "❌ Frontend build output missing or empty"
    exit 1
fi

echo ""
echo "🎉 ALL CI/CD QUALITY CHECKS PASSED!"
echo "✅ Your code will pass CI/CD pipeline"
EOF

# Make the script executable
chmod +x /tmp/ci-validation-script.sh

# Run the validation script inside the Docker container
if docker run --rm -v /tmp/ci-validation-script.sh:/ci-validation-script.sh vigor-ci-validation /ci-validation-script.sh; then
    print_success "🎉 ALL CI/CD VALIDATION CHECKS PASSED!"
    print_success "Your code is ready for CI/CD pipeline"
else
    print_error "❌ CI/CD validation failed"
    print_error "These are the exact same failures you would see in CI/CD"
    exit 1
fi

# Cleanup
rm -f /tmp/ci-validation-script.sh
print_success "Docker CI/CD validation completed successfully"
