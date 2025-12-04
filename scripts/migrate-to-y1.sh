#!/bin/bash
# Script to migrate Vigor Function App from FC1 to Y1 Consumption Plan
# This script validates prerequisites and performs the migration

set -e

# Configuration
RESOURCE_GROUP="vigor-rg"
LOCATION="westus2"
FUNCTION_APP_NAME="vigor-backend"
NEW_FUNCTION_APP_NAME="vigor-backend-y1"
STORAGE_ACCOUNT="vigorstorage"
KEY_VAULT_NAME="vigor-keyvault"
COSMOS_ACCOUNT="vigor-cosmos"
APP_INSIGHTS_NAME="vigor-ai"

echo "======================================"
echo "Vigor Function App Y1 Migration Script"
echo "======================================"

# Check Azure CLI login
echo ""
echo "1. Checking Azure CLI authentication..."
if ! az account show > /dev/null 2>&1; then
    echo "ERROR: Not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "   Using subscription: $SUBSCRIPTION_NAME"

# Check resource group exists
echo ""
echo "2. Checking resource group..."
if ! az group show --name $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "ERROR: Resource group '$RESOURCE_GROUP' not found."
    exit 1
fi
echo "   Resource group '$RESOURCE_GROUP' exists."

# Check current Function App status
echo ""
echo "3. Checking current Function App status..."
if az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    CURRENT_PLAN=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "appServicePlanId" -o tsv | xargs basename)
    CURRENT_STATE=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "state" -o tsv)
    echo "   Current Function App: $FUNCTION_APP_NAME"
    echo "   Current Plan: $CURRENT_PLAN"
    echo "   Current State: $CURRENT_STATE"
else
    echo "   No existing Function App found. Will create new."
fi

# Check required resources exist
echo ""
echo "4. Checking required resources..."
ERRORS=0

if ! az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "   ERROR: Storage account '$STORAGE_ACCOUNT' not found."
    ERRORS=$((ERRORS+1))
else
    echo "   Storage account '$STORAGE_ACCOUNT' exists."
fi

if ! az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "   ERROR: Key Vault '$KEY_VAULT_NAME' not found."
    ERRORS=$((ERRORS+1))
else
    echo "   Key Vault '$KEY_VAULT_NAME' exists."
fi

if ! az cosmosdb show --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "   ERROR: Cosmos DB '$COSMOS_ACCOUNT' not found."
    ERRORS=$((ERRORS+1))
else
    echo "   Cosmos DB '$COSMOS_ACCOUNT' exists."
fi

if ! az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "   ERROR: Application Insights '$APP_INSIGHTS_NAME' not found."
    ERRORS=$((ERRORS+1))
else
    echo "   Application Insights '$APP_INSIGHTS_NAME' exists."
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "ERROR: $ERRORS required resources are missing. Please deploy base infrastructure first."
    exit 1
fi

# Deploy Y1 Function App
echo ""
echo "5. Deploying Y1 Consumption Plan Function App..."
echo "   Using template: infrastructure/bicep/function-app-y1.bicep"

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file infrastructure/bicep/function-app-y1.bicep \
    --parameters \
        functionAppName=$NEW_FUNCTION_APP_NAME \
        location=$LOCATION \
        storageAccountName=$STORAGE_ACCOUNT \
        keyVaultName=$KEY_VAULT_NAME \
        cosmosAccountName=$COSMOS_ACCOUNT \
        applicationInsightsName=$APP_INSIGHTS_NAME \
    --name "vigor-y1-deployment-$(date +%Y%m%d-%H%M%S)"

# Check deployment status
echo ""
echo "6. Verifying deployment..."
NEW_STATE=$(az functionapp show --name $NEW_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "state" -o tsv)
NEW_PLAN=$(az functionapp show --name $NEW_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "appServicePlanId" -o tsv | xargs basename)
HOST_STATUS=$(az functionapp show --name $NEW_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "hostingEnvironmentProfile" -o tsv 2>/dev/null || echo "None")

echo "   Function App: $NEW_FUNCTION_APP_NAME"
echo "   Plan: $NEW_PLAN"
echo "   State: $NEW_STATE"

# Deploy function code
echo ""
echo "7. Deploying function code..."
cd functions-modernized
func azure functionapp publish $NEW_FUNCTION_APP_NAME --python
cd ..

# Test function host
echo ""
echo "8. Testing function host..."
sleep 30  # Wait for deployment to settle

HEALTH_URL="https://${NEW_FUNCTION_APP_NAME}.azurewebsites.net/api/health"
echo "   Testing: $HEALTH_URL"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "   SUCCESS: Function App is responding (HTTP $HTTP_STATUS)"
else
    echo "   WARNING: Function App returned HTTP $HTTP_STATUS"
    echo "   Checking function host logs..."
    az functionapp log deployment show --name $NEW_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP | head -20
fi

# Summary
echo ""
echo "======================================"
echo "Migration Complete"
echo "======================================"
echo "New Function App URL: https://${NEW_FUNCTION_APP_NAME}.azurewebsites.net"
echo ""
echo "Next steps:"
echo "1. Test all API endpoints using the health check endpoint"
echo "2. Update frontend VITE_API_BASE_URL to point to new Function App"
echo "3. Configure Gemini API key in Key Vault if not already set"
echo "4. Run E2E tests against new backend"
echo "5. Once validated, delete old Function App: az functionapp delete --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP"
