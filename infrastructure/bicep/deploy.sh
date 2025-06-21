#!/bin/bash

# Vigor Bicep Infrastructure Deployment Script
# Deploys Azure infrastructure using Bicep templates

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
RESOURCE_GROUP="vigor-rg"
DATABASE_RESOURCE_GROUP="vigor-db-rg"
LOCATION="Central US"  # Single region for cost optimization
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters.bicepparam"

print_status "🚀 Vigor Bicep Infrastructure Deployment"
echo "=========================================="
echo ""

# Check if we're in the correct directory
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    print_error "Bicep template file not found. Please run from infrastructure/bicep directory."
    echo "Expected file: $TEMPLATE_FILE"
    exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! az bicep version &> /dev/null; then
    print_warning "Bicep CLI not found. Installing..."
    az bicep install
    print_success "Bicep CLI installed"
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

# Check for required environment variables
print_status "Checking required environment variables..."

REQUIRED_VARS=(
    "POSTGRES_ADMIN_PASSWORD"
    "SECRET_KEY"
    "ADMIN_EMAIL"
)

OPTIONAL_VARS=(
    "OPENAI_API_KEY"
    "GEMINI_API_KEY"
    "PERPLEXITY_API_KEY"
)

missing_vars=()

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    print_error "Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please set these variables before running the script:"
    echo "export POSTGRES_ADMIN_PASSWORD=\"your-secure-password\""
    echo "export SECRET_KEY=\"your-jwt-secret-key\""
    echo "export ADMIN_EMAIL=\"admin@vigor-fitness.com\""
    echo ""
    echo "Optional variables (can be empty):"
    echo "export OPENAI_API_KEY=\"your-openai-key\""
    echo "export GEMINI_API_KEY=\"your-gemini-key\""
    echo "export PERPLEXITY_API_KEY=\"your-perplexity-key\""
    exit 1
fi

print_success "Environment variables validated"
echo ""

# Create resource groups
print_status "Creating resource groups for dual-group architecture..."

# Create database resource group (persistent resources)
print_status "Creating database resource group: $DATABASE_RESOURCE_GROUP"
if az group show --name "$DATABASE_RESOURCE_GROUP" &> /dev/null; then
    print_warning "Database resource group $DATABASE_RESOURCE_GROUP already exists"
else
    az group create --name "$DATABASE_RESOURCE_GROUP" --location "$LOCATION"
    print_success "Created database resource group: $DATABASE_RESOURCE_GROUP"
fi

# Create main resource group (compute resources)
print_status "Creating main resource group: $RESOURCE_GROUP"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "Main resource group $RESOURCE_GROUP already exists"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_success "Created main resource group: $RESOURCE_GROUP"
fi
echo ""

# Validate template
print_status "Validating Bicep template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
                 secretKey="$SECRET_KEY" \
                 adminEmail="$ADMIN_EMAIL" \
                 openaiApiKey="${OPENAI_API_KEY:-}" \
                 geminiApiKey="${GEMINI_API_KEY:-}" \
                 perplexityApiKey="${PERPLEXITY_API_KEY:-}" \
    > /dev/null

print_success "Template validation passed"
echo ""

# Deploy infrastructure
print_status "Deploying infrastructure to Azure..."
echo "This may take 10-15 minutes..."
echo ""

DEPLOYMENT_NAME="vigor-deployment-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMETERS_FILE" \
    --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
                 secretKey="$SECRET_KEY" \
                 adminEmail="$ADMIN_EMAIL" \
                 openaiApiKey="${OPENAI_API_KEY:-}" \
                 geminiApiKey="${GEMINI_API_KEY:-}" \
                 perplexityApiKey="${PERPLEXITY_API_KEY:-}" \
    --output table

if [[ $? -eq 0 ]]; then
    print_success "Infrastructure deployment completed successfully!"
else
    print_error "Infrastructure deployment failed!"
    exit 1
fi

echo ""

# Get deployment outputs
print_status "Retrieving deployment information..."

BACKEND_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.backendUrl.value \
    --output tsv)

FRONTEND_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.frontendUrl.value \
    --output tsv)

CONTAINER_REGISTRY=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.containerRegistryLoginServer.value \
    --output tsv)

KEY_VAULT_NAME=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.keyVaultName.value \
    --output tsv)

echo ""
print_success "🎉 Vigor infrastructure deployed successfully!"
echo ""
print_status "Deployment Summary - Dual Resource Group Architecture:"
echo "  ✅ Main Resource Group: $RESOURCE_GROUP (compute resources)"
echo "  ✅ Database Resource Group: $DATABASE_RESOURCE_GROUP (persistent resources)"
echo "  ✅ Backend URL: $BACKEND_URL"
echo "  ✅ Frontend URL: $FRONTEND_URL"
echo "  ✅ Container Registry: $CONTAINER_REGISTRY"
echo "  ✅ Key Vault: $KEY_VAULT_NAME (in $DATABASE_RESOURCE_GROUP)"
echo ""
print_status "🔥 Cost Optimization - Pause/Resume Operations:"
echo "  💰 To PAUSE (save costs): Delete '$RESOURCE_GROUP' resource group"
echo "  ▶️  To RESUME: Re-run this deployment script (data preserved in '$DATABASE_RESOURCE_GROUP')"
echo ""
print_status "Next Steps:"
echo "  1. Update your GitHub Actions workflow to use Bicep deployment"
echo "  2. Configure GitHub secrets with the new resource names"
echo "  3. Deploy your application containers"
echo "  4. Test the application functionality"
echo ""
print_status "GitHub Secrets to Update:"
echo "  - CONTAINER_REGISTRY_LOGIN_SERVER=$CONTAINER_REGISTRY"
echo "  - KEY_VAULT_NAME=$KEY_VAULT_NAME"
echo ""
print_status "Monitoring URLs:"
echo "  - Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo "  - Application Insights: Check the resource group in Azure Portal"
echo ""
print_warning "Don't forget to clean up old Terraform resources if migration is successful!"
