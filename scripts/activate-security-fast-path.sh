#!/bin/bash
# Script to quickly trigger the security fix fast path for an urgent security fix

set -eo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <pr-number> <severity:critical|high|medium|low>"
  exit 1
fi

PR_NUMBER=$1
SEVERITY=$2

# Validate severity
if [[ ! "$SEVERITY" =~ ^(critical|high|medium|low)$ ]]; then
  echo "Error: Severity must be one of: critical, high, medium, low"
  exit 1
fi

echo "🔒 Activating Security Fix Fast Path for PR #$PR_NUMBER (Severity: $SEVERITY)"

# Add required labels
gh pr edit $PR_NUMBER --add-label "security-fix"

if [ "$SEVERITY" == "critical" ] || [ "$SEVERITY" == "high" ]; then
  gh pr edit $PR_NUMBER --add-label "priority-critical"
  # For critical/high severity, add emergency override
  gh pr edit $PR_NUMBER --add-label "emergency-override"
fi

# Trigger the security-fix-path workflow
echo "🚀 Triggering security fix fast path workflow..."
gh workflow run security-fix-path.yml -f prNumber=$PR_NUMBER

echo "✅ Security fix fast path activated!"
echo "🔔 The security team has been notified."
echo "📝 For detailed instructions, see: docs/agent_communication_guide.md"
