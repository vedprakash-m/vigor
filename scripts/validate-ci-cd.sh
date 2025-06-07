#!/bin/bash

# Vigor CI/CD Pipeline Local Validation Script
# Tests all pipeline components locally before committing

set -e

echo "🔧 Vigor CI/CD Pipeline Local Validation"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    local is_critical=${3:-true}

    echo -e "\n${BLUE}🧪 Testing: ${test_name}${NC}"
    echo "Command: $test_command"

    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        ((TESTS_FAILED++))

        if [ "$is_critical" = true ]; then
            echo -e "${RED}💥 Critical test failed. Please fix before pushing.${NC}"
            return 1
        fi
    fi
}

# Function to check if command exists
check_dependency() {
    local cmd=$1
    local install_hint=$2

    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}❌ Missing dependency: $cmd${NC}"
        echo -e "   Install with: $install_hint"
        return 1
    else
        echo -e "${GREEN}✅ Found: $cmd${NC}"
    fi
}

echo -e "\n${BLUE}📋 Checking Dependencies${NC}"
echo "========================"

check_dependency "python3" "brew install python3"
check_dependency "node" "brew install node"
check_dependency "npm" "comes with node"
check_dependency "docker" "brew install docker"

echo -e "\n${BLUE}🏗️ Backend Validation${NC}"
echo "====================="

# Check if virtual environment exists
if [ ! -d "backend/venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found. Creating...${NC}"
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
fi

# Backend formatting and linting
run_test "Backend Black Formatting" "cd backend && source venv/bin/activate && python -m black --check --diff ." true
run_test "Backend isort Import Sorting" "cd backend && source venv/bin/activate && python -m isort --check-only --diff ." true
run_test "Backend Flake8 Linting" "cd backend && source venv/bin/activate && flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics" true
run_test "Backend Tests" "cd backend && source venv/bin/activate && pytest -v" true
run_test "Backend Security Check (Bandit)" "cd backend && source venv/bin/activate && bandit -r . --severity-level medium" false

echo -e "\n${BLUE}🎨 Frontend Validation${NC}"
echo "======================"

# Check if node_modules exists
if [ ! -d "frontend/node_modules" ]; then
    echo -e "${YELLOW}⚠️ Node modules not found. Installing...${NC}"
    cd frontend
    npm install
    cd ..
fi

# Frontend linting and testing
run_test "Frontend TypeScript Check" "cd frontend && npx tsc --noEmit" true
run_test "Frontend ESLint" "cd frontend && npm run lint" true
run_test "Frontend Tests" "cd frontend && npm test -- --coverage --watchAll=false" true
run_test "Frontend Build" "cd frontend && npm run build" true

echo -e "\n${BLUE}🐳 Docker Validation${NC}"
echo "===================="

run_test "Backend Docker Build" "cd backend && docker build -t vigor-backend-test ." false

echo -e "\n${BLUE}🏗️ Infrastructure Validation${NC}"
echo "============================="

if [ -f "infrastructure/terraform/main.tf" ]; then
    run_test "Terraform Format Check" "cd infrastructure/terraform && terraform fmt -check -recursive" false
    run_test "Terraform Validation" "cd infrastructure/terraform && terraform init && terraform validate" false
else
    echo -e "${YELLOW}⚠️ Terraform files not found. Skipping infrastructure validation.${NC}"
fi

echo -e "\n${BLUE}🔒 Security Validation${NC}"
echo "======================"

run_test "Trivy Filesystem Scan" "docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest fs /workspace --severity HIGH,CRITICAL" false

echo -e "\n${BLUE}📊 Validation Summary${NC}"
echo "===================="

echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All validation tests passed!${NC}"
    echo -e "${GREEN}✅ Ready to commit and push changes${NC}"

    echo -e "\n${BLUE}🚀 Next Steps:${NC}"
    echo "1. git add ."
    echo "2. git commit -m 'fix: CI/CD pipeline improvements'"
    echo "3. git push origin main"
    echo "4. Monitor GitHub Actions for pipeline execution"

    exit 0
else
    echo -e "\n${RED}💥 Some validation tests failed!${NC}"
    echo -e "${YELLOW}⚠️ Please fix the issues before pushing${NC}"

    echo -e "\n${BLUE}🔧 Common Fixes:${NC}"
    echo "- Backend formatting: cd backend && source venv/bin/activate && black . && isort ."
    echo "- Frontend linting: cd frontend && npm run lint:fix"
    echo "- Run tests: npm test (frontend) or pytest (backend)"

    exit 1
fi
