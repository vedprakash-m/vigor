#!/bin/bash

# Vigor CI/CD GitHub Secrets Setup Script
# This script helps configure the required GitHub repository secrets

set -e

echo "🚀 Vigor CI/CD GitHub Secrets Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first:${NC}"
    echo "   brew install gh"
    echo "   or visit: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️ Not authenticated with GitHub CLI. Please run:${NC}"
    echo "   gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is installed and authenticated${NC}"

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_description=$2
    local is_required=${3:-true}

    echo -e "\n${BLUE}🔑 Setting up: ${secret_name}${NC}"
    echo -e "   ${secret_description}"

    if [ "$is_required" = true ]; then
        echo -e "${YELLOW}   This secret is REQUIRED for the CI/CD pipeline${NC}"
    else
        echo -e "   This secret is optional but recommended"
    fi

    read -p "   Enter value (or press Enter to skip): " secret_value

    if [ -n "$secret_value" ]; then
        gh secret set "$secret_name" --body "$secret_value"
        echo -e "${GREEN}   ✅ Secret '$secret_name' set successfully${NC}"
    else
        if [ "$is_required" = true ]; then
            echo -e "${YELLOW}   ⚠️ Required secret '$secret_name' was skipped${NC}"
        else
            echo -e "   ⏭️ Optional secret '$secret_name' was skipped"
        fi
    fi
}

echo -e "\n${BLUE}📋 Required Secrets Setup${NC}"
echo "=========================="

# Azure Authentication (Required for deployment)
set_secret "AZURE_CLIENT_ID" "Azure Service Principal Client ID" true
set_secret "AZURE_TENANT_ID" "Azure Tenant ID" true
set_secret "AZURE_SUBSCRIPTION_ID" "Azure Subscription ID" true
set_secret "AZURE_CLIENT_SECRET" "Azure Service Principal Client Secret" true

# Azure Container Registry
set_secret "ACR_USERNAME" "Azure Container Registry Username" true
set_secret "ACR_PASSWORD" "Azure Container Registry Password" true

# Database Configuration
set_secret "POSTGRES_ADMIN_PASSWORD" "PostgreSQL Admin Password" true
set_secret "DATABASE_URL_DEV" "Development Database Connection String" false
set_secret "DATABASE_URL_STAGING" "Staging Database Connection String" false
set_secret "DATABASE_URL_PRODUCTION" "Production Database Connection String" false

# Application Security
set_secret "SECRET_KEY" "JWT Secret Key for Application" true

echo -e "\n${BLUE}📋 Optional Secrets Setup${NC}"
echo "========================="

# LLM API Keys (Optional - fallback provider works without them)
set_secret "OPENAI_API_KEY" "OpenAI API Key for GPT models" false
set_secret "GOOGLE_AI_API_KEY" "Google AI API Key for Gemini models" false
set_secret "PERPLEXITY_API_KEY" "Perplexity API Key" false

# Azure Static Web Apps (Optional - for frontend deployment)
set_secret "AZURE_STATIC_WEB_APPS_API_TOKEN_DEV" "Azure Static Web Apps API Token (Dev)" false
set_secret "AZURE_STATIC_WEB_APPS_API_TOKEN_STAGING" "Azure Static Web Apps API Token (Staging)" false
set_secret "AZURE_STATIC_WEB_APPS_API_TOKEN_PRODUCTION" "Azure Static Web Apps API Token (Production)" false

# Coverage and Monitoring (Optional)
set_secret "CODECOV_TOKEN" "Codecov Upload Token for Coverage Reports" false

echo -e "\n${GREEN}🎉 GitHub Secrets Setup Complete!${NC}"
echo "=================================="

echo -e "\n${BLUE}📝 Next Steps:${NC}"
echo "1. Review the secrets in your GitHub repository settings"
echo "2. Set up Azure infrastructure using Terraform"
echo "3. Push to the main/develop branch to trigger the CI/CD pipeline"
echo "4. Monitor the pipeline execution in GitHub Actions"

echo -e "\n${BLUE}📖 Additional Resources:${NC}"
echo "- Azure Setup Guide: docs/CI_CD_SETUP_GUIDE.md"
echo "- Infrastructure Setup: infrastructure/terraform/"
echo "- Pipeline Documentation: .github/workflows/ci_cd_pipeline.yml"

echo -e "\n${YELLOW}⚠️ Security Notes:${NC}"
echo "- Keep your secrets secure and rotate them regularly"
echo "- Use least-privilege principles for Azure service principals"
echo "- Monitor secret usage in GitHub Actions logs"
echo "- Consider using Azure Key Vault for production secrets"

echo -e "\n${GREEN}✨ Happy Deploying! ✨${NC}"
