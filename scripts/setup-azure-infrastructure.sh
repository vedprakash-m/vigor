#!/bin/bash

# Vigor Azure Infrastructure Setup Script
# Automates the creation of Azure resources needed for CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Configuration
SUBSCRIPTION_ID=""
RESOURCE_GROUP="vigor-rg"
LOCATION="eastus"
CONTAINER_REGISTRY="vigoracr"
SERVICE_PRINCIPAL_NAME="vigor-cicd-sp"
TERRAFORM_STATE_RG="vigor-rg"
TERRAFORM_STATE_STORAGE="vigortfstate$(openssl rand -hex 4)"

print_status "🚀 Vigor Azure Infrastructure Setup"
echo "====================================="
echo ""

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI is not installed. Please install it first."
    echo "Visit: https://cli.github.com/"
    exit 1
fi

print_success "Prerequisites check passed"
echo ""

# Azure login check
print_status "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    print_warning "Not logged into Azure. Initiating login..."
    az login
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
print_success "Using Azure subscription: $SUBSCRIPTION_ID"
echo ""

# Function to create resource group
create_resource_group() {
    local rg_name=$1
    local location=$2

    print_status "Creating resource group: $rg_name"

    if az group show --name "$rg_name" &> /dev/null; then
        print_warning "Resource group $rg_name already exists"
    else
        az group create --name "$rg_name" --location "$location"
        print_success "Created resource group: $rg_name"
    fi
}

# Function to create container registry
create_container_registry() {
    print_status "Creating Azure Container Registry: $CONTAINER_REGISTRY"

    if az acr show --name "$CONTAINER_REGISTRY" &> /dev/null; then
        print_warning "Container registry $CONTAINER_REGISTRY already exists"
    else
        az acr create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$CONTAINER_REGISTRY" \
            --sku Basic \
            --admin-enabled true
        print_success "Created container registry: $CONTAINER_REGISTRY"
    fi

    # Get ACR credentials
    print_status "Getting container registry credentials..."
    ACR_LOGIN_SERVER=$(az acr show --name "$CONTAINER_REGISTRY" --query loginServer --output tsv)
    ACR_USERNAME=$(az acr credential show --name "$CONTAINER_REGISTRY" --query username --output tsv)
    ACR_PASSWORD=$(az acr credential show --name "$CONTAINER_REGISTRY" --query passwords[0].value --output tsv)

    print_success "Container registry configured"
    echo "  Login Server: $ACR_LOGIN_SERVER"
    echo "  Username: $ACR_USERNAME"
    echo ""
}

# Function to create service principal for CI/CD
create_service_principal() {
    print_status "Creating service principal for CI/CD: $SERVICE_PRINCIPAL_NAME"

    # Check if service principal already exists
    if az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[0].appId" --output tsv | grep -q "."; then
        print_warning "Service principal $SERVICE_PRINCIPAL_NAME already exists"
        APP_ID=$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[0].appId" --output tsv)
        print_status "Using existing service principal: $APP_ID"
    else
        # Create service principal
        SP_OUTPUT=$(az ad sp create-for-rbac \
            --name "$SERVICE_PRINCIPAL_NAME" \
            --role contributor \
            --scopes "/subscriptions/$SUBSCRIPTION_ID" \
            --output json)

        APP_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
        CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.password')
        TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenant')

        print_success "Created service principal: $APP_ID"
    fi

    # Get tenant ID if not set
    if [ -z "$TENANT_ID" ]; then
        TENANT_ID=$(az account show --query tenantId --output tsv)
    fi
}

# Function to setup Terraform backend
setup_terraform_backend() {
    print_status "Setting up Terraform backend storage..."

    # Create resource group for Terraform state
    create_resource_group "$TERRAFORM_STATE_RG" "$LOCATION"

    # Create storage account for Terraform state
    if az storage account show --name "$TERRAFORM_STATE_STORAGE" --resource-group "$TERRAFORM_STATE_RG" &> /dev/null; then
        print_warning "Storage account $TERRAFORM_STATE_STORAGE already exists"
    else
        az storage account create \
            --name "$TERRAFORM_STATE_STORAGE" \
            --resource-group "$TERRAFORM_STATE_RG" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --encryption-services blob

        print_success "Created storage account: $TERRAFORM_STATE_STORAGE"
    fi

    # Create blob container for Terraform state
    az storage container create \
        --name tfstate \
        --account-name "$TERRAFORM_STATE_STORAGE" \
        --auth-mode login

    print_success "Terraform backend configured"
}

# Function to configure GitHub secrets
configure_github_secrets() {
    print_status "Configuring GitHub repository secrets..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository. Please run from the project root."
        exit 1
    fi

    # Get repository info
    REPO_URL=$(git config --get remote.origin.url)
    REPO_INFO=$(echo "$REPO_URL" | sed -E 's|.*github\.com[/:]([^/]+)/([^/]+)\.git|\1/\2|')

    print_status "Setting secrets for repository: $REPO_INFO"

    # Set Azure secrets
    echo "$APP_ID" | gh secret set AZURE_CLIENT_ID
    echo "$CLIENT_SECRET" | gh secret set AZURE_CLIENT_SECRET
    echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID
    echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID

    # Set container registry secrets
    echo "$ACR_LOGIN_SERVER" | gh secret set ACR_LOGIN_SERVER
    echo "$ACR_USERNAME" | gh secret set ACR_USERNAME
    echo "$ACR_PASSWORD" | gh secret set ACR_PASSWORD

    # Set Terraform backend secrets
    echo "$TERRAFORM_STATE_RG" | gh secret set TFSTATE_RESOURCE_GROUP
    echo "$TERRAFORM_STATE_STORAGE" | gh secret set TFSTATE_STORAGE_ACCOUNT

    print_success "GitHub secrets configured"
}

# Function to generate application secrets
generate_application_secrets() {
    print_status "Generating application secrets..."

    # Generate secure secrets
    POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')
    SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n')

    # Set application secrets
    echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_ADMIN_PASSWORD
    echo "$SECRET_KEY" | gh secret set SECRET_KEY
    echo "admin@vigor.app" | gh secret set ADMIN_EMAIL

    print_success "Application secrets generated and set"
}

# Main execution
print_status "Starting Azure infrastructure setup..."
echo ""

# Step 1: Create main resource group
create_resource_group "$RESOURCE_GROUP" "$LOCATION"

# Step 2: Create container registry
create_container_registry

# Step 3: Create service principal
create_service_principal

# Step 4: Setup Terraform backend
setup_terraform_backend

# Step 5: Configure GitHub secrets
configure_github_secrets

# Step 6: Generate application secrets
generate_application_secrets

echo ""
print_success "🎉 Azure infrastructure setup completed!"
echo ""
print_status "Summary of created resources:"
echo "  ✅ Resource Group: $RESOURCE_GROUP"
echo "  ✅ Container Registry: $ACR_LOGIN_SERVER"
echo "  ✅ Service Principal: $SERVICE_PRINCIPAL_NAME ($APP_ID)"
echo "  ✅ Terraform Backend: $TERRAFORM_STATE_STORAGE"
echo "  ✅ GitHub Secrets: Configured"
echo ""
print_status "Next steps:"
echo "  1. Review and commit any configuration changes"
echo "  2. Run 'terraform init' to initialize Terraform backend"
echo "  3. Run 'terraform plan' to review infrastructure changes"
echo "  4. Trigger GitHub Actions workflow to test deployment"
echo ""
print_warning "Important: Save these credentials securely:"
echo "  Service Principal ID: $APP_ID"
echo "  Tenant ID: $TENANT_ID"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo ""
