#!/bin/bash
# Vigor Secret Detection Pre-commit Hook
# This script runs BEFORE the standard pre-commit hooks
# It specifically targets high-risk files that may contain secrets

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔐 Vigor Secret Scanner - Pre-commit Check${NC}"
echo "=============================================="

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}✅ No files staged${NC}"
    exit 0
fi

BLOCKED=0

# HIGH-RISK FILE PATTERNS - Block these file types entirely unless they contain placeholders
HIGH_RISK_PATTERNS=(
    "\.bicepparam$"
    "parameters.*\.json$"
    "local\.settings\.json$"
    "\.env$"
    "\.env\.local$"
    "\.env\.production$"
)

# Files that should NEVER be committed
NEVER_COMMIT=(
    "parameters-modernized.bicepparam"
    "local.settings.json"
    ".env"
    ".env.local"
)

echo -e "\n📁 Scanning staged files for secrets..."

# Check for files that should never be committed
for file in $STAGED_FILES; do
    for never in "${NEVER_COMMIT[@]}"; do
        if [[ "$file" == *"$never" ]] && [[ "$file" != *".example"* ]]; then
            echo -e "${RED}❌ BLOCKED: '$file' should not be committed!${NC}"
            echo "   This file typically contains secrets. Add to .gitignore or rename to .example"
            BLOCKED=1
        fi
    done
done

# SECRET PATTERNS - These patterns indicate real secrets
SECRET_PATTERNS=(
    # Azure OpenAI keys (32-char hex)
    '[a-f0-9]{32}'
    # Azure Storage keys (88 chars base64 ending with ==)
    '[A-Za-z0-9+/]{86}=='
    # OpenAI API keys
    'sk-[a-zA-Z0-9]{24,}'
    # GitHub PAT
    'ghp_[a-zA-Z0-9]{36}'
    # Google API Key
    'AIza[0-9A-Za-z_-]{35}'
    # AWS Access Key
    'AKIA[0-9A-Z]{16}'
    # Generic long secret-looking strings in key/secret/password context
)

# PLACEHOLDER PATTERNS - These are OK
PLACEHOLDER_PATTERNS=(
    'your-.*-here'
    'placeholder'
    'PLACEHOLDER'
    'changeme'
    'CHANGEME'
    'example'
    'EXAMPLE'
    'GET_FROM_'
    'TODO'
    '<.*>'
)

# Check high-risk files for actual secrets
for file in $STAGED_FILES; do
    # Skip example files
    if [[ "$file" == *".example"* ]]; then
        continue
    fi

    # Check if it's a high-risk file
    IS_HIGH_RISK=0
    for pattern in "${HIGH_RISK_PATTERNS[@]}"; do
        if echo "$file" | grep -qE "$pattern"; then
            IS_HIGH_RISK=1
            break
        fi
    done

    if [ $IS_HIGH_RISK -eq 1 ]; then
        echo -e "\n${YELLOW}⚠️  High-risk file detected: $file${NC}"

        # Get the staged content
        CONTENT=$(git show ":$file" 2>/dev/null || cat "$file" 2>/dev/null || echo "")

        # Check for 32-char hex strings (Azure keys)
        if echo "$CONTENT" | grep -qE "['\"=][a-f0-9]{32}['\"]"; then
            # Make sure it's not a placeholder
            HAS_PLACEHOLDER=0
            for placeholder in "${PLACEHOLDER_PATTERNS[@]}"; do
                if echo "$CONTENT" | grep -qiE "$placeholder"; then
                    HAS_PLACEHOLDER=1
                    break
                fi
            done

            if [ $HAS_PLACEHOLDER -eq 0 ]; then
                echo -e "${RED}❌ BLOCKED: Potential Azure API key detected in '$file'${NC}"
                echo "   Found 32-character hex string that appears to be a real secret"
                BLOCKED=1
            fi
        fi

        # Check for base64 storage keys
        if echo "$CONTENT" | grep -qE "[A-Za-z0-9+/]{86}=="; then
            echo -e "${RED}❌ BLOCKED: Potential Azure Storage key detected in '$file'${NC}"
            BLOCKED=1
        fi

        # Check for param with key/secret/password followed by actual value (not placeholder)
        if echo "$CONTENT" | grep -qiE "param\s+(.*key|.*secret|.*password)\s*=\s*['\"][^'\"]*['\"]"; then
            LINE=$(echo "$CONTENT" | grep -iE "param\s+(.*key|.*secret|.*password)\s*=\s*['\"]" | head -1)
            # Check if it contains a placeholder
            IS_PLACEHOLDER=0
            for placeholder in "${PLACEHOLDER_PATTERNS[@]}"; do
                if echo "$LINE" | grep -qiE "$placeholder"; then
                    IS_PLACEHOLDER=1
                    break
                fi
            done

            if [ $IS_PLACEHOLDER -eq 0 ]; then
                echo -e "${RED}❌ BLOCKED: Secret parameter detected in '$file'${NC}"
                echo "   Line: $LINE"
                BLOCKED=1
            fi
        fi
    fi
done

# Check ALL staged content for OpenAI and other critical patterns
echo -e "\n🔍 Scanning all staged content for known secret patterns..."

STAGED_DIFF=$(git diff --cached)

# OpenAI API key
if echo "$STAGED_DIFF" | grep -qE '\+.*sk-[a-zA-Z0-9]{24,}'; then
    echo -e "${RED}❌ BLOCKED: OpenAI API key pattern detected${NC}"
    BLOCKED=1
fi

# GitHub PAT
if echo "$STAGED_DIFF" | grep -qE '\+.*ghp_[a-zA-Z0-9]{36}'; then
    echo -e "${RED}❌ BLOCKED: GitHub Personal Access Token detected${NC}"
    BLOCKED=1
fi

# Google API Key
if echo "$STAGED_DIFF" | grep -qE '\+.*AIza[0-9A-Za-z_-]{35}'; then
    echo -e "${RED}❌ BLOCKED: Google API key detected${NC}"
    BLOCKED=1
fi

# AWS Access Key
if echo "$STAGED_DIFF" | grep -qE '\+.*AKIA[0-9A-Z]{16}'; then
    echo -e "${RED}❌ BLOCKED: AWS Access Key detected${NC}"
    BLOCKED=1
fi

if [ $BLOCKED -eq 1 ]; then
    echo -e "\n${RED}=============================================="
    echo "❌ COMMIT BLOCKED: Secrets detected!"
    echo "=============================================="
    echo -e "${NC}"
    echo "To fix this:"
    echo "1. Remove the secrets from your staged files"
    echo "2. Use environment variables or Azure Key Vault"
    echo "3. For IaC files, use .example suffix and add originals to .gitignore"
    echo ""
    echo "If this is a false positive, you can:"
    echo "  - Add a placeholder pattern (e.g., 'your-key-here')"
    echo "  - Update .github/gitleaks.toml allowlist"
    echo ""
    echo -e "${YELLOW}⚠️  Never use --no-verify to bypass this check!${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ No secrets detected in staged files${NC}"
exit 0
