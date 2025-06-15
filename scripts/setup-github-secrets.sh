#!/bin/bash

# GitHub Actions Secrets Setup Script for Vigor CI/CD Pipeline
# This script helps configure the required GitHub secrets for the CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER=""
REPO_NAME=""
GITHUB_TOKEN=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."

    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi

    if ! command -v az &> /dev/null; then
        print_error "Azure CLI (az) is not installed. Please install it first."
        exit 1
    fi

    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed. Please install it first."
        exit 1
    fi

    print_success "All prerequisites are installed."
}

# Function to authenticate with GitHub
setup_github_auth() {
    print_status "Setting up GitHub authentication..."

    if ! gh auth status &> /dev/null; then
        print_warning "Not authenticated with GitHub. Please run 'gh auth login' first."
        gh auth login
    fi

    print_success "GitHub authentication verified."
}

# Function to get repository information
get_repo_info() {
    if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
        print_status "Getting repository information..."

        # Try to get from git remote
        if git remote get-url origin &> /dev/null; then
            REPO_URL=$(git remote get-url origin)
            if [[ $REPO_URL == *"github.com"* ]]; then
                REPO_OWNER=$(echo $REPO_URL | sed -n 's/.*github\.com[:/]\([^/]*\)\/\([^/]*\)\.git.*/\1/p')
                REPO_NAME=$(echo $REPO_URL | sed -n 's/.*github\.com[:/]\([^/]*\)\/\([^/]*\)\.git.*/\2/p')
            fi
        fi

        # If still empty, prompt user
        if [[ -z "$REPO_OWNER" ]]; then
            read -p "Enter GitHub repository owner: " REPO_OWNER
        fi

        if [[ -z "$REPO_NAME" ]]; then
            read -p "Enter GitHub repository name: " REPO_NAME
        fi
    fi

    print_success "Repository: $REPO_OWNER/$REPO_NAME"
}

# Function to create Azure Service Principal
create_service_principal() {
    print_status "Creating Azure Service Principal..."

    # Get Azure subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        print_error "Failed to get Azure subscription ID. Please run 'az login' first."
        exit 1
    fi

    print_status "Using subscription: $SUBSCRIPTION_ID"

    # Create service principal
    SP_NAME="vigor-cicd-$(date +%s)"
    SP_JSON=$(az ad sp create-for-rbac --name "$SP_NAME" --role "Contributor" --scopes "/subscriptions/$SUBSCRIPTION_ID" --sdk-auth)

    if [[ $? -eq 0 ]]; then
        print_success "Service Principal created: $SP_NAME"

        # Extract values
        CLIENT_ID=$(echo $SP_JSON | jq -r '.clientId')
        CLIENT_SECRET=$(echo $SP_JSON | jq -r '.clientSecret')
        TENANT_ID=$(echo $SP_JSON | jq -r '.tenantId')

        # Set GitHub secrets
        echo "$SP_JSON" | gh secret set AZURE_CREDENTIALS -R "$REPO_OWNER/$REPO_NAME"
        echo "$CLIENT_ID" | gh secret set AZURE_CLIENT_ID -R "$REPO_OWNER/$REPO_NAME"
        echo "$CLIENT_SECRET" | gh secret set AZURE_CLIENT_SECRET -R "$REPO_OWNER/$REPO_NAME"
        echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID -R "$REPO_OWNER/$REPO_NAME"
        echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID -R "$REPO_OWNER/$REPO_NAME"

        print_success "Azure credentials configured in GitHub secrets."
    else
        print_error "Failed to create service principal."
        exit 1
    fi
}

# Function to generate application secrets
generate_app_secrets() {
    print_status "Generating application secrets..."

    # Generate SECRET_KEY (32 characters)
    SECRET_KEY=$(openssl rand -hex 32)
    echo "$SECRET_KEY" | gh secret set SECRET_KEY -R "$REPO_OWNER/$REPO_NAME"

    # Generate POSTGRES_ADMIN_PASSWORD (16 characters)
    POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_ADMIN_PASSWORD -R "$REPO_OWNER/$REPO_NAME"

    print_success "Application secrets generated and configured."
    print_warning "POSTGRES_ADMIN_PASSWORD: $POSTGRES_PASSWORD (save this securely!)"
}

# Function to setup API keys (user input required)
setup_api_keys() {
    print_status "Setting up AI provider API keys..."

    echo "Please enter your AI provider API keys (press Enter to skip):"

    read -p "OpenAI API Key: " -s OPENAI_KEY
    echo
    if [[ -n "$OPENAI_KEY" ]]; then
        echo "$OPENAI_KEY" | gh secret set OPENAI_API_KEY -R "$REPO_OWNER/$REPO_NAME"
        print_success "OpenAI API key configured."
    fi

    read -p "Google AI API Key: " -s GOOGLE_KEY
    echo
    if [[ -n "$GOOGLE_KEY" ]]; then
        echo "$GOOGLE_KEY" | gh secret set GOOGLE_AI_API_KEY -R "$REPO_OWNER/$REPO_NAME"
        print_success "Google AI API key configured."
    fi

    read -p "Perplexity API Key: " -s PERPLEXITY_KEY
    echo
    if [[ -n "$PERPLEXITY_KEY" ]]; then
        echo "$PERPLEXITY_KEY" | gh secret set PERPLEXITY_API_KEY -R "$REPO_OWNER/$REPO_NAME"
        print_success "Perplexity API key configured."
    fi
}

# Function to setup database URLs (placeholder values)
setup_database_urls() {
    print_status "Setting up database connection strings..."

    # These are placeholder values that will be updated after infrastructure deployment
    DEV_DB_URL="postgresql://vigoradmin:password@vigor-dev-db.postgres.database.azure.com:5432/vigor?sslmode=require"
    PROD_DB_URL="postgresql://vigoradmin:password@vigor-production-db.postgres.database.azure.com:5432/vigor?sslmode=require"

    echo "$DEV_DB_URL" | gh secret set DATABASE_URL_DEV -R "$REPO_OWNER/$REPO_NAME"
    echo "$PROD_DB_URL" | gh secret set DATABASE_URL_PRODUCTION -R "$REPO_OWNER/$REPO_NAME"

    print_success "Database URLs configured (placeholder values)."
    print_warning "Update these URLs after infrastructure deployment."
}

# Function to setup Static Web App tokens (placeholder values)
setup_static_web_app_tokens() {
    print_status "Setting up Static Web App tokens..."

    # These are placeholder values that will be updated after Static Web App creation
    DEV_TOKEN="placeholder-token-dev"
    PROD_TOKEN="placeholder-token-production"

    echo "$DEV_TOKEN" | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN_DEV -R "$REPO_OWNER/$REPO_NAME"
    echo "$PROD_TOKEN" | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN_PRODUCTION -R "$REPO_OWNER/$REPO_NAME"

    print_success "Static Web App tokens configured (placeholder values)."
    print_warning "Update these tokens after Static Web App creation."
}

# Function to create GitHub environments
create_github_environments() {
    print_status "Creating GitHub environments..."

    # Note: GitHub CLI doesn't have direct environment creation, so we'll provide instructions
    print_warning "Please manually create the following environments in GitHub:"
    echo "1. Go to https://github.com/$REPO_OWNER/$REPO_NAME/settings/environments"
    echo "2. Create environments: development, production"
    echo "3. Configure protection rules as described in the setup guide"
}

# Function to display summary
display_summary() {
    print_success "GitHub secrets setup completed!"
    echo
    echo "Configured secrets:"
    echo "✓ AZURE_CREDENTIALS"
    echo "✓ AZURE_CLIENT_ID"
    echo "✓ AZURE_CLIENT_SECRET"
    echo "✓ AZURE_TENANT_ID"
    echo "✓ AZURE_SUBSCRIPTION_ID"
    echo "✓ SECRET_KEY"
    echo "✓ POSTGRES_ADMIN_PASSWORD"
    echo "✓ OPENAI_API_KEY (if provided)"
    echo "✓ GOOGLE_AI_API_KEY (if provided)"
    echo "✓ PERPLEXITY_API_KEY (if provided)"
    echo "✓ DATABASE_URL_* (placeholder values)"
    echo "✓ AZURE_STATIC_WEB_APPS_API_TOKEN_* (placeholder values)"
    echo
    print_warning "Next steps:"
    echo "1. Create GitHub environments (development, production)"
    echo "2. Deploy infrastructure using Terraform"
    echo "3. Update database URLs with actual values"
    echo "4. Update Static Web App tokens with actual values"
    echo "5. Test the CI/CD pipeline with a push to develop branch"
    echo
    echo "For detailed instructions, see docs/CI_CD_SETUP_GUIDE.md"
}

# Main function
main() {
    echo "=========================================="
    echo "Vigor CI/CD Pipeline - GitHub Secrets Setup"
    echo "=========================================="
    echo

    check_prerequisites
    setup_github_auth
    get_repo_info

    echo
    print_status "This script will:"
    echo "1. Create Azure Service Principal"
    echo "2. Generate application secrets"
    echo "3. Configure GitHub secrets"
    echo "4. Setup API keys (user input required)"
    echo

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled."
        exit 0
    fi

    create_service_principal
    generate_app_secrets
    setup_api_keys
    setup_database_urls
    setup_static_web_app_tokens
    create_github_environments
    display_summary
}

# Run main function
main "$@"
