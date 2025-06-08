#!/bin/bash
# West US 2 Deployment Script for Vigor
# Optimized for west coast users with all resources collocated

set -e

echo "🌎 Deploying Vigor to West US 2 (Optimized for West Coast Users)"
echo "=================================================="

# Configuration
RESOURCE_GROUP="vigor-rg"
LOCATION="West US 2"
DEPLOYMENT_NAME="vigor-westus2-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔍 $1${NC}"
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

# Check if logged in to Azure
print_status "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi
print_success "Azure login verified"

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_status "Using subscription: $SUBSCRIPTION_ID"

# Check if resource group exists, create if it doesn't
print_status "Checking resource group: $RESOURCE_GROUP"
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "Resource group $RESOURCE_GROUP doesn't exist. Creating in $LOCATION..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_success "Resource group created successfully"
else
    print_success "Resource group exists"
fi

# Check quota availability in West US 2
print_status "Checking quota availability in West US 2..."
echo "📊 App Service quota check:"
az vm list-usage --location "$LOCATION" --query "[?contains(name.value, 'Standard')]" --output table || true

echo ""
echo "📊 Container Registry quota check:"
az acr check-name --name "vigoracr$(date +%s)" --query "nameAvailable" || true

# Validate Bicep template
print_status "Validating Bicep template..."
if az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters parameters.bicepparam \
    --parameters postgresAdminPassword="TempPassword123!" \
                 secretKey="temp-secret-key-for-validation" \
                 adminEmail="admin@vigor-fitness.com" \
                 openaiApiKey="" \
                 geminiApiKey="" \
                 perplexityApiKey="" \
    --output none; then
    print_success "Bicep template validation passed"
else
    print_error "Bicep template validation failed"
    exit 1
fi

# Deploy infrastructure
print_status "Deploying infrastructure to West US 2..."
echo "🚀 Deployment name: $DEPLOYMENT_NAME"
echo "📍 Region: $LOCATION"
echo "🎯 Target users: West Coast"
echo ""

# Check if required secrets are set
if [ -z "$POSTGRES_ADMIN_PASSWORD" ]; then
    print_warning "POSTGRES_ADMIN_PASSWORD not set. Using temporary password."
    POSTGRES_ADMIN_PASSWORD="TempPassword123!"
fi

if [ -z "$SECRET_KEY" ]; then
    print_warning "SECRET_KEY not set. Using temporary key."
    SECRET_KEY="temp-secret-key-$(date +%s)"
fi

if [ -z "$ADMIN_EMAIL" ]; then
    ADMIN_EMAIL="admin@vigor-fitness.com"
fi

# Deploy with all parameters
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --template-file main.bicep \
    --parameters parameters.bicepparam \
    --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
                 secretKey="$SECRET_KEY" \
                 adminEmail="$ADMIN_EMAIL" \
                 openaiApiKey="${OPENAI_API_KEY:-}" \
                 geminiApiKey="${GEMINI_API_KEY:-}" \
                 perplexityApiKey="${PERPLEXITY_API_KEY:-}" \
    --verbose

if [ $? -eq 0 ]; then
    print_success "Infrastructure deployment completed successfully!"

    echo ""
    echo "🌟 Deployment Summary"
    echo "===================="
    echo "📍 Region: West US 2"
    echo "🎯 Optimized for: West Coast users"
    echo "⚡ Expected latency: <20ms for CA/WA/OR users"
    echo "💰 Tier: Basic (cost-optimized)"
    echo ""

    # Get deployment outputs
    print_status "Retrieving deployment information..."
    echo "📋 Deployed resources:"
    az resource list --resource-group "$RESOURCE_GROUP" --output table

    echo ""
    echo "🌐 Application URLs (will be available after app deployment):"

    # Get App Service URL
    APP_SERVICE_NAME=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "[0].defaultHostName" --output tsv 2>/dev/null || echo "Not deployed yet")
    if [ "$APP_SERVICE_NAME" != "Not deployed yet" ]; then
        echo "Backend API: https://$APP_SERVICE_NAME"
    fi

    # Get Static Web App URL
    SWA_URL=$(az staticwebapp list --resource-group "$RESOURCE_GROUP" --query "[0].defaultHostname" --output tsv 2>/dev/null || echo "Not deployed yet")
    if [ "$SWA_URL" != "Not deployed yet" ]; then
        echo "Frontend: https://$SWA_URL"
    fi

    echo ""
    print_success "🚀 Ready for application deployment via GitHub Actions!"
    echo ""
    echo "Next steps:"
    echo "1. Set up GitHub secrets (if not already done)"
    echo "2. Push to main branch to trigger CI/CD deployment"
    echo "3. Monitor deployment in GitHub Actions"

else
    print_error "Infrastructure deployment failed"
    echo ""
    echo "🔍 Troubleshooting tips:"
    echo "• Check quota availability in West US 2"
    echo "• Verify all required parameters are set"
    echo "• Try a different region if quota issues persist"
    echo "• Check Azure status page for service issues"
    exit 1
fi
