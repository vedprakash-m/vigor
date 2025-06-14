#!/bin/bash
# Script to quickly set up major release bypass mechanisms

set -eo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <pr-number> [enable-release-mode:true|false]"
  echo "Example: $0 123 true"
  exit 1
fi

PR_NUMBER=$1
ENABLE_RELEASE_MODE=${2:-false}

echo "🚀 Setting up major release bypass for PR #$PR_NUMBER"

# Add release bypass labels
gh pr edit $PR_NUMBER --add-label "priority-release"
gh pr edit $PR_NUMBER --add-label "size-limit-exempt"

# Add helpful comment to PR
COMMENT="## 🚀 Major Release Bypass Activated

This PR has been configured with bypass labels for a major release:

- \`priority-release\`: Allows expedited review and merge
- \`size-limit-exempt\`: Bypasses PR size limits

**Additional options that may be helpful:**
- \`extended-review\`: For PRs that need longer review time
- \`emergency-override\`: For urgent issues that must bypass checks

See \`docs/agent_communication_guide.md\` for more details on working with these bypass mechanisms."

gh pr comment $PR_NUMBER --body "$COMMENT"

# Optionally enable release mode
if [ "$ENABLE_RELEASE_MODE" == "true" ]; then
  echo "🔄 Enabling release mode..."
  if [ -f "toggle_release_mode.sh" ]; then
    ./toggle_release_mode.sh enable
  else
    echo "⚠️ toggle_release_mode.sh not found. Creating release mode flag manually."
    mkdir -p .github
    echo '{"releaseMode": true}' > .github/release-config.json
    git add .github/release-config.json
    git commit -m "Enable release mode for major release"
    git push
  fi
  echo "✅ Release mode enabled!"
fi

echo "✅ Major release bypass setup complete!"
echo "📝 For detailed instructions on communicating this with coding agents, see: docs/agent_communication_guide.md"
