#!/bin/bash
# Creates a properly configured security fix PR with minimal public details

set -eo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <branch-name> <brief-description>"
  exit 1
fi

BRANCH_NAME=$1
DESCRIPTION=$2

echo "🔒 Creating security fix branch..."
git checkout -b "$BRANCH_NAME"

echo "📝 Creating template security PR message..."
cat > /tmp/security-pr-message.md << EOL
Security fix - Details provided in private channel

<!--
DO NOT provide vulnerability details here.
Security team has been notified via private channels.
-->
EOL

echo "🚀 When ready to create PR, run:"
echo "--------------------------------------------"
echo "git push -u origin $BRANCH_NAME"
echo "gh pr create --title \"Security fix: $DESCRIPTION\" --body-file /tmp/security-pr-message.md --label security-fix"
echo "--------------------------------------------"
echo "✅ Then notify the security team via the private channel."
