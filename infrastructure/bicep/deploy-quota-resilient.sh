#!/bin/bash

# Vigor - Quota-Resilient Azure Deployment Script
# Tries multiple regions and SKUs to avoid quota limitations

set -e

echo "🚀 Starting quota-resilient Azure deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="vigor-prod-rg"
DEPLOYMENT_NAME="vigor-deployment-$(date +%Y%m%d-%H%M%S)"

# Deployment strategies (ordered by preference: cost -> quota availability)
declare -a STRATEGIES=(
    "Central US:F1:Free tier in Central US"
    "Central US:B1:Basic tier in Central US"
    "West US:F1:Free tier in West US"
    "West US:B1:Basic tier in West US"
    "East US 2:F1:Free tier in East US 2"
    "East US 2:B1:Basic tier in East US 2"
    "West US 2:B1:Basic tier in West US 2"
    "South Central US:B1:Basic tier in South Central US"
)

# Function to try deployment with specific parameters
try_deployment() {
    local region=$1
    local sku=$2
    local description=$3

    echo -e "${YELLOW}📍 Trying deployment: $description${NC}"
    echo "   Region: $region"
    echo "   App Service SKU: $sku"

    # Update parameters file dynamically
    cat > parameters-temp.bicepparam << EOF
using './main.bicep'

param environment = 'prod'
param location = '$region'
param appName = 'vigor'
param postgresAdminUsername = 'vigoradmin'
param adminEmail = 'admin@vigor-fitness.com'
param appServiceSku = '$sku'

// Secrets from environment variables
param postgresAdminPassword = '$POSTGRES_ADMIN_PASSWORD'
param secretKey = '$SECRET_KEY'
param openaiApiKey = '$OPENAI_API_KEY'
param geminiApiKey = '$GEMINI_API_KEY'
param perplexityApiKey = '$PERPLEXITY_API_KEY'
EOF

    # Try the deployment
    if az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file main.bicep \
        --parameters parameters-temp.bicepparam \
        --name "$DEPLOYMENT_NAME-$(echo $region | tr ' ' '-' | tr '[:upper:]' '[:lower:]')" \
        --timeout 600 \
        --only-show-errors; then

        echo -e "${GREEN}✅ SUCCESS: Deployment completed with $description${NC}"
        echo -e "${GREEN}🎉 Infrastructure deployed successfully!${NC}"

        # Get deployment outputs
        echo ""
        echo "📋 Deployment Summary:"
        az deployment group show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$DEPLOYMENT_NAME-$(echo $region | tr ' ' '-' | tr '[:upper:]' '[:lower:]')" \
            --query 'properties.outputs' \
            --output table

        # Cleanup temp file
        rm -f parameters-temp.bicepparam
        return 0
    else
        echo -e "${RED}❌ FAILED: $description${NC}"
        echo ""
        return 1
    fi
}

# Main deployment logic
echo "🔍 Checking Azure login status..."
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

echo "📋 Current subscription:"
az account show --query '{name:name, id:id}' --output table

echo ""
echo "🎯 Resource Group: $RESOURCE_GROUP"

# Ensure resource group exists
if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "📦 Creating resource group..."
    az group create --name "$RESOURCE_GROUP" --location "Central US"
fi

echo ""
echo "🚀 Starting quota-resilient deployment process..."
echo "   Will try ${#STRATEGIES[@]} different configurations until one succeeds."
echo ""

# Try each strategy until one succeeds
for strategy in "${STRATEGIES[@]}"; do
    IFS=':' read -r region sku description <<< "$strategy"

    if try_deployment "$region" "$sku" "$description"; then
        echo ""
        echo -e "${GREEN}🎊 DEPLOYMENT COMPLETE!${NC}"
        echo ""
        echo "💰 Cost Estimate:"
        if [[ "$sku" == "F1" ]]; then
            echo "   App Service Plan: $0/month (Free tier)"
            echo "   Total estimated cost: ~$20/month"
        else
            echo "   App Service Plan: ~$13/month (Basic B1)"
            echo "   Total estimated cost: ~$33/month"
        fi
        echo ""
        echo "🔗 Next steps:"
        echo "   1. Update your domain/DNS settings"
        echo "   2. Configure CI/CD pipeline"
        echo "   3. Run application health checks"

        exit 0
    fi

    # Brief pause between attempts
    sleep 2
done

# If we get here, all strategies failed
echo ""
echo -e "${RED}💥 ALL DEPLOYMENT STRATEGIES FAILED${NC}"
echo ""
echo "🚨 This indicates severe quota limitations on your Azure subscription."
echo ""
echo "📞 Recommended actions:"
echo "   1. Contact Azure Support to request quota increase"
echo "   2. Try a different Azure subscription"
echo "   3. Consider using Azure Container Instances instead"
echo "   4. Use a different cloud provider (AWS, GCP)"
echo ""
echo "📧 Azure Support: https://azure.microsoft.com/support/options/"

# Cleanup
rm -f parameters-temp.bicepparam

exit 1
