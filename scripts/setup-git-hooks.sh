#!/bin/bash

# Setup Git Hooks for Secret Protection
echo "🔧 Setting up Git hooks for secret protection..."

# Create git hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp .githooks/pre-commit .git/hooks/pre-commit.secrets
chmod +x .git/hooks/pre-commit.secrets

# Create a combined pre-commit hook that runs both secret detection and CI validation
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Run secrets detection hook
./.git/hooks/pre-commit.secrets
if [ $? -ne 0 ]; then
  exit 1
fi

# Run lightweight CI validation in pre-commit mode
bash ./scripts/local-ci-validate.sh --pre-commit
if [ $? -ne 0 ]; then
  echo "❌ Local CI validation failed! Fix issues before committing."
  echo "   To bypass validation: git commit --no-verify (NOT recommended)"
  exit 1
fi

exit 0
EOF

chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed (secrets + CI validation)"

# Install detect-secrets if not present
if ! command -v detect-secrets &> /dev/null; then
    echo "📦 Installing detect-secrets..."
    pip install detect-secrets
fi

# Generate/update secrets baseline
echo "🔍 Updating secrets baseline..."
detect-secrets scan --baseline .secrets.baseline --force-use-all-plugins

echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "The following protection is now active:"
echo "✅ Pre-commit hook will scan for secrets before each commit"
echo "✅ Pre-commit hook will run local CI validation checks"
echo "✅ GitHub Actions will scan on push/PR"
echo "✅ Baseline file tracks known false positives"
echo ""
echo "🔧 Usage:"
echo "• Commit normally - hooks will run automatically"
echo "• To bypass hooks: git commit --no-verify (NOT recommended)"
echo "• To update baseline: detect-secrets scan --baseline .secrets.baseline"
echo ""
echo "⚠️  Remember: Never commit real API keys, passwords, or secrets!"
