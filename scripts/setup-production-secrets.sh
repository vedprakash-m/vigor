#!/bin/bash

# Vigor GitHub Secrets Setup for Production Deployment
# This script helps set up the required GitHub secrets for the CI/CD pipeline

set -e

REPO_OWNER="vedprakash-m"
REPO_NAME="vigor"

echo "🔑 Vigor GitHub Secrets Setup for Production Deployment"
echo "======================================================="
echo ""
echo "This script will help you set up the required GitHub secrets for the Vigor CI/CD pipeline."
echo "Make sure you have the GitHub CLI installed and authenticated."
echo ""

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI is not authenticated. Please authenticate first:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to check if a secret exists
check_secret() {
    local secret_name=$1
    if gh secret list --repo "$REPO_OWNER/$REPO_NAME" | grep -q "^$secret_name"; then
        echo "✅ $secret_name (already set)"
        return 0
    else
        echo "❌ $secret_name (missing)"
        return 1
    fi
}

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3

    echo ""
    echo "Setting $secret_name..."
    echo "Description: $description"

    if [ -n "$secret_value" ]; then
        echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME"
        echo "✅ $secret_name set successfully"
    else
        echo "Please enter the value for $secret_name:"
        read -s secret_input
        echo "$secret_input" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME"
        echo "✅ $secret_name set successfully"
    fi
}

# Function to generate a secure random string
generate_secret() {
    openssl rand -hex 32
}

echo "📋 Checking existing secrets:"
echo "=============================="

# Check Azure authentication secrets
echo ""
echo "🔐 Azure Authentication (OIDC-based):"
check_secret "AZURE_CLIENT_ID"
check_secret "AZURE_TENANT_ID"
check_secret "AZURE_SUBSCRIPTION_ID"

# Check application secrets
echo ""
echo "🔧 Application Secrets:"
check_secret "POSTGRES_ADMIN_PASSWORD"
check_secret "SECRET_KEY"
check_secret "ADMIN_EMAIL"

# Check optional AI provider keys
echo ""
echo "🤖 AI Provider Keys (Optional):"
check_secret "OPENAI_API_KEY"
check_secret "GEMINI_API_KEY"
check_secret "PERPLEXITY_API_KEY"

# Check container registry secrets
echo ""
echo "🐳 Container Registry:"
check_secret "ACR_USERNAME"
check_secret "ACR_PASSWORD"

# Check optional secrets
echo ""
echo "📊 Optional Integrations:"
check_secret "CODECOV_TOKEN"

echo ""
echo "======================================================="
echo ""

# Azure authentication secrets setup
echo "🔐 Azure Authentication Setup:"
echo "=============================="
echo ""
echo "The following Azure secrets are required for OIDC authentication:"
echo "- AZURE_CLIENT_ID: 42aae4cc-5dd0-4469-9f10-87e45dc45088"
echo "- AZURE_TENANT_ID: 80fe68b7-105c-4fb9-ab03-c9a818e35848"
echo "- AZURE_SUBSCRIPTION_ID: 8c48242c-a20e-448a-ac0f-be75ac5ebad0"
echo ""

if ! check_secret "AZURE_CLIENT_ID" > /dev/null; then
    set_secret "AZURE_CLIENT_ID" "42aae4cc-5dd0-4469-9f10-87e45dc45088" "Azure Service Principal Client ID for OIDC authentication"
fi

if ! check_secret "AZURE_TENANT_ID" > /dev/null; then
    set_secret "AZURE_TENANT_ID" "80fe68b7-105c-4fb9-ab03-c9a818e35848" "Azure Tenant ID for OIDC authentication"
fi

if ! check_secret "AZURE_SUBSCRIPTION_ID" > /dev/null; then
    set_secret "AZURE_SUBSCRIPTION_ID" "8c48242c-a20e-448a-ac0f-be75ac5ebad0" "Azure Subscription ID for resource deployment"
fi

# Application secrets setup
echo ""
echo "🔧 Application Secrets Setup:"
echo "============================="
echo ""

if ! check_secret "POSTGRES_ADMIN_PASSWORD" > /dev/null; then
    echo "Generating secure PostgreSQL admin password..."
    POSTGRES_PASSWORD=$(generate_secret)
    set_secret "POSTGRES_ADMIN_PASSWORD" "$POSTGRES_PASSWORD" "PostgreSQL admin password for database access"
fi

if ! check_secret "SECRET_KEY" > /dev/null; then
    echo "Generating secure JWT secret key..."
    JWT_SECRET=$(generate_secret)
    set_secret "SECRET_KEY" "$JWT_SECRET" "JWT secret key for token signing and verification"
fi

if ! check_secret "ADMIN_EMAIL" > /dev/null; then
    set_secret "ADMIN_EMAIL" "" "Admin email address for system notifications and admin account"
fi

# Container Registry secrets setup
echo ""
echo "🐳 Container Registry Setup:"
echo "============================"
echo ""
echo "Container Registry credentials will be auto-generated during Azure deployment."
echo "You can set them manually if you have existing ACR credentials:"
echo ""

read -p "Do you want to set Container Registry credentials now? (y/N): " setup_acr
if [[ $setup_acr =~ ^[Yy]$ ]]; then
    if ! check_secret "ACR_USERNAME" > /dev/null; then
        set_secret "ACR_USERNAME" "" "Azure Container Registry username"
    fi

    if ! check_secret "ACR_PASSWORD" > /dev/null; then
        set_secret "ACR_PASSWORD" "" "Azure Container Registry password"
    fi
else
    echo "⏭️  Skipping ACR credentials - they will be set up during deployment"
fi

# AI Provider Keys setup
echo ""
echo "🤖 AI Provider Keys Setup:"
echo "=========================="
echo ""
echo "AI provider keys are optional but recommended for full functionality:"
echo "- Gemini API: Cost-effective primary provider"
echo "- OpenAI API: Premium quality option"
echo "- Perplexity API: Balanced performance option"
echo ""

read -p "Do you want to set up AI provider keys now? (y/N): " setup_ai
if [[ $setup_ai =~ ^[Yy]$ ]]; then
    if ! check_secret "GEMINI_API_KEY" > /dev/null; then
        echo ""
        echo "Gemini API Key (Primary provider - cost-effective):"
        echo "Get your key from: https://aistudio.google.com/app/apikey"
        set_secret "GEMINI_API_KEY" "" "Google Gemini API key for AI-powered features"
    fi

    if ! check_secret "OPENAI_API_KEY" > /dev/null; then
        echo ""
        echo "OpenAI API Key (Premium option):"
        echo "Get your key from: https://platform.openai.com/api-keys"
        set_secret "OPENAI_API_KEY" "" "OpenAI API key for premium AI features"
    fi

    if ! check_secret "PERPLEXITY_API_KEY" > /dev/null; then
        echo ""
        echo "Perplexity API Key (Balanced option):"
        echo "Get your key from: https://www.perplexity.ai/settings/api"
        set_secret "PERPLEXITY_API_KEY" "" "Perplexity API key for balanced AI performance"
    fi
else
    echo "⏭️  Skipping AI provider keys - you can set them up later for enhanced functionality"
fi

# Optional integrations
echo ""
echo "📊 Optional Integrations:"
echo "========================"
echo ""

read -p "Do you want to set up Codecov integration for test coverage? (y/N): " setup_codecov
if [[ $setup_codecov =~ ^[Yy]$ ]]; then
    if ! check_secret "CODECOV_TOKEN" > /dev/null; then
        echo ""
        echo "Codecov Token:"
        echo "Get your token from: https://codecov.io/gh/$REPO_OWNER/$REPO_NAME/settings"
        set_secret "CODECOV_TOKEN" "" "Codecov token for test coverage reporting"
    fi
else
    echo "⏭️  Skipping Codecov - test coverage will still work without reporting"
fi

echo ""
echo "🎉 GitHub Secrets Setup Complete!"
echo "================================="
echo ""
echo "✅ All required secrets have been configured for production deployment."
echo ""
echo "📋 Next Steps:"
echo "1. Verify all secrets are set correctly:"
echo "   gh secret list --repo $REPO_OWNER/$REPO_NAME"
echo ""
echo "2. Test the CI/CD pipeline by pushing a commit or running the workflow manually:"
echo "   gh workflow run \"Vigor CI/CD Pipeline\" --repo $REPO_OWNER/$REPO_NAME"
echo ""
echo "3. Monitor the deployment:"
echo "   gh run list --repo $REPO_OWNER/$REPO_NAME"
echo ""
echo "4. Once deployed, verify with:"
echo "   ./scripts/verify-deployment.sh"
echo ""
echo "🚀 Your Vigor application is ready for production deployment!"
