#!/bin/bash
# Azure Federated Identity Setup for GitHub Actions
# This script helps configure federated identity for passwordless Azure authentication

set -e

echo "🔐 Azure Federated Identity Setup for Vigor"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
print_step "Checking prerequisites"

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not installed"
    echo "Install with: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Check Azure login
if ! az account show &> /dev/null; then
    print_error "Not logged into Azure CLI"
    echo "Run: az login"
    exit 1
fi

# Check GitHub login
if ! gh auth status &> /dev/null; then
    print_error "Not logged into GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Get repository information
if ! gh repo view &> /dev/null; then
    print_error "Not in a GitHub repository"
    exit 1
fi

REPO_NAME=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
REPO_OWNER=$(echo $REPO_NAME | cut -d'/' -f1)
REPO_REPO=$(echo $REPO_NAME | cut -d'/' -f2)

print_success "Repository: $REPO_NAME"

# Get Azure subscription info
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

print_success "Azure Subscription: $SUBSCRIPTION_ID"
print_success "Azure Tenant: $TENANT_ID"

# App registration name
APP_NAME="vigor-github-actions"

print_step "Creating Azure App Registration"

# Check if app registration exists
if az ad app list --display-name "$APP_NAME" --query "[0].appId" --output tsv | grep -q .; then
    CLIENT_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" --output tsv)
    print_success "App registration '$APP_NAME' already exists: $CLIENT_ID"
else
    # Create app registration
    CLIENT_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)
    print_success "Created app registration '$APP_NAME': $CLIENT_ID"
fi

print_step "Creating service principal"

# Check if service principal exists
if az ad sp list --display-name "$APP_NAME" --query "[0].id" --output tsv | grep -q .; then
    SP_ID=$(az ad sp list --display-name "$APP_NAME" --query "[0].id" --output tsv)
    print_success "Service principal already exists: $SP_ID"
else
    # Create service principal
    SP_ID=$(az ad sp create --id $CLIENT_ID --query id --output tsv)
    print_success "Created service principal: $SP_ID"
fi

print_step "Assigning Contributor role"

# Assign contributor role to the subscription
az role assignment create \
    --role "Contributor" \
    --assignee $CLIENT_ID \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output none || print_warning "Role assignment may already exist"

print_success "Assigned Contributor role to subscription"

print_step "Configuring federated credentials"

# Configure federated credential for main branch
MAIN_SUBJECT="repo:$REPO_NAME:ref:refs/heads/main"
if az ad app federated-credential list --id $CLIENT_ID --query "[?subject=='$MAIN_SUBJECT']" --output tsv | grep -q .; then
    print_success "Federated credential for main branch already exists"
else
    az ad app federated-credential create \
        --id $CLIENT_ID \
        --parameters '{
            "name": "vigor-main-branch",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "'$MAIN_SUBJECT'",
            "description": "Vigor main branch deployment",
            "audiences": ["api://AzureADTokenExchange"]
        }' --output none
    print_success "Created federated credential for main branch"
fi

# Configure federated credential for production environment
PROD_SUBJECT="repo:$REPO_NAME:environment:production"
if az ad app federated-credential list --id $CLIENT_ID --query "[?subject=='$PROD_SUBJECT']" --output tsv | grep -q .; then
    print_success "Federated credential for production environment already exists"
else
    az ad app federated-credential create \
        --id $CLIENT_ID \
        --parameters '{
            "name": "vigor-production-env",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "'$PROD_SUBJECT'",
            "description": "Vigor production environment",
            "audiences": ["api://AzureADTokenExchange"]
        }' --output none
    print_success "Created federated credential for production environment"
fi

print_step "Setting GitHub secrets"

# Set required secrets
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"

print_success "Set Azure authentication secrets"

# Check for other required secrets
REQUIRED_SECRETS=("DATABASE_URL" "SECRET_KEY" "OPENAI_API_KEY")
MISSING_SECRETS=()

for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! gh secret list | grep -q "^$secret"; then
        MISSING_SECRETS+=("$secret")
    fi
done

if [ ${#MISSING_SECRETS[@]} -gt 0 ]; then
    print_warning "Missing application secrets:"
    for secret in "${MISSING_SECRETS[@]}"; do
        echo "  - $secret"
    done
    echo ""
    print_warning "Set these manually with: gh secret set SECRET_NAME"
    print_warning "For DATABASE_URL: Use Azure PostgreSQL connection string"
    print_warning "For SECRET_KEY: Generate with: openssl rand -hex 32"
    print_warning "For OPENAI_API_KEY: Get from OpenAI platform"
else
    print_success "All application secrets are configured"
fi

print_step "Creating production environment"

# Create GitHub environment if it doesn't exist
if ! gh api repos/:owner/:repo/environments/production &> /dev/null; then
    gh api --method PUT repos/:owner/:repo/environments/production \
        --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
        --field prevent_self_review=false
    print_success "Created GitHub production environment"
else
    print_success "GitHub production environment already exists"
fi

echo ""
echo -e "${GREEN}🎉 Azure Federated Identity Setup Complete!${NC}"
echo "============================================="
echo -e "${GREEN}✅ App Registration: $CLIENT_ID${NC}"
echo -e "${GREEN}✅ Service Principal: $SP_ID${NC}"
echo -e "${GREEN}✅ Federated credentials configured${NC}"
echo -e "${GREEN}✅ GitHub secrets set${NC}"
echo -e "${GREEN}✅ Production environment created${NC}"
echo ""
echo -e "${BLUE}Your GitHub Actions can now authenticate to Azure! 🚀${NC}"

if [ ${#MISSING_SECRETS[@]} -gt 0 ]; then
    echo ""
    print_warning "Don't forget to set the missing application secrets before deployment"
fi
