#!/bin/bash

# Vigor Backend Quality Checks Script
# This script runs all the same quality checks that the CI pipeline runs

set -e  # Exit on first error

echo "🚀 Running Vigor Backend Quality Checks..."
echo "============================================="

# Change to backend directory
cd "$(dirname "$0")"

echo ""
echo "📦 Installing/updating quality tools..."
pip install black isort flake8 bandit mypy pytest pytest-cov safety

echo ""
echo "🎨 Running Black code formatter..."
if black --check --diff .; then
    echo "✅ Black formatting: PASS"
else
    echo "❌ Black formatting: FAIL"
    echo "💡 Run: python -m black . to fix formatting"
    exit 1
fi

echo ""
echo "📥 Running isort import sorter..."
if isort --check-only --diff .; then
    echo "✅ Import sorting: PASS"
else
    echo "❌ Import sorting: FAIL"
    echo "💡 Run: python -m isort . to fix imports"
    exit 1
fi

echo ""
echo "🔍 Running flake8 linter..."
if flake8 .; then
    echo "✅ Flake8 linting: PASS"
else
    echo "⚠️ Flake8 linting: ISSUES FOUND (see above)"
fi

echo ""
echo "🔒 Running bandit security scan..."
if bandit -c .bandit -r . --severity-level high; then
    echo "✅ Security scan: PASS (no high-severity issues)"
else
    echo "❌ Security scan: HIGH-SEVERITY ISSUES FOUND"
    exit 1
fi

echo ""
echo "📝 Running mypy type checking..."
if mypy . --config-file=mypy.ini; then
    echo "✅ Type checking: PASS"
else
    echo "⚠️ Type checking: ISSUES FOUND (see above)"
fi

echo ""
echo "🛡️ Running safety dependency check..."
if safety check; then
    echo "✅ Dependency security: PASS"
else
    echo "⚠️ Dependency security: VULNERABILITIES FOUND (see above)"
fi

echo ""
echo "🧪 Running tests..."
if pytest --cov=. --cov-report=term-missing -v; then
    echo "✅ Tests: PASS"
else
    echo "⚠️ Tests: FAILURES (see above)"
fi

echo ""
echo "🎉 Quality checks completed!"
echo "💡 Check the reports in bandit_report.json and coverage.xml"
echo "🌐 View detailed coverage report: open htmlcov/index.html"
