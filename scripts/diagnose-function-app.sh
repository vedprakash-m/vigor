#!/bin/bash
# Vigor Function App Diagnostic Script
# Checks current Azure Function App status and configuration

set -e

echo "🔍 Vigor Function App Diagnostics"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Resource details
RESOURCE_GROUP="vigor-rg"
FUNCTION_APP_NAME="vigor-backend"

echo "📋 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged into Azure. Please run: az login${NC}"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Logged in to subscription: $SUBSCRIPTION${NC}"
echo ""

echo "🔍 Checking Function App existence..."
if ! az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${RED}❌ Function App '$FUNCTION_APP_NAME' not found in resource group '$RESOURCE_GROUP'${NC}"
    echo "Available Function Apps:"
    az functionapp list --resource-group $RESOURCE_GROUP --query "[].name" -o table
    exit 1
fi
echo -e "${GREEN}✅ Function App found${NC}"
echo ""

echo "📊 Function App Details:"
echo "----------------------"
az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP \
    --query "{name:name, location:location, state:state, kind:kind, runtime:siteConfig.linuxFxVersion}" -o table
echo ""

echo "🔧 App Service Plan Details:"
echo "----------------------------"
PLAN_ID=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query "serverFarmId" -o tsv)
PLAN_NAME=$(echo $PLAN_ID | awk -F'/' '{print $NF}')
az appservice plan show --name $PLAN_NAME --resource-group $RESOURCE_GROUP \
    --query "{name:name, sku:sku.name, tier:sku.tier, kind:kind, status:status}" -o table
echo ""

echo "🌐 Function App Runtime Status:"
echo "--------------------------------"
RUNTIME_STATUS=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP \
    --query "state" -o tsv)
echo "State: $RUNTIME_STATUS"

HOST_STATUS=$(az rest --method get --uri "https://${FUNCTION_APP_NAME}.azurewebsites.net/admin/host/status" 2>&1 || echo "Unable to reach")
if [[ $HOST_STATUS == *"Unable to reach"* ]]; then
    echo -e "${RED}❌ Function host is not responding${NC}"
else
    echo -e "${GREEN}✅ Function host is responding${NC}"
fi
echo ""

echo "📜 Recent Application Logs (last 100 lines):"
echo "--------------------------------------------"
az webapp log tail --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --provider application &
LOG_PID=$!
sleep 10
kill $LOG_PID 2>/dev/null || true
echo ""

echo "🔐 Environment Variables Check:"
echo "--------------------------------"
echo "Checking critical environment variables..."
CRITICAL_VARS=("FUNCTIONS_WORKER_RUNTIME" "FUNCTIONS_EXTENSION_VERSION" "COSMOS_DB_ENDPOINT" "GOOGLE_AI_API_KEY" "JWT_SECRET_KEY")
for VAR in "${CRITICAL_VARS[@]}"; do
    VALUE=$(az functionapp config appsettings list --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP \
        --query "[?name=='$VAR'].value" -o tsv 2>/dev/null)
    if [ -z "$VALUE" ]; then
        echo -e "${RED}❌ $VAR: Not set${NC}"
    elif [[ $VAR == *"KEY"* ]] || [[ $VAR == *"SECRET"* ]]; then
        echo -e "${GREEN}✅ $VAR: [REDACTED]${NC}"
    else
        echo -e "${GREEN}✅ $VAR: $VALUE${NC}"
    fi
done
echo ""

echo "📦 Deployed Functions List:"
echo "---------------------------"
az functionapp function list --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP \
    --query "[].{Name:name, TriggerType:config.bindings[0].type}" -o table 2>/dev/null || echo "No functions deployed yet"
echo ""

echo "🏥 Health Check Attempt:"
echo "------------------------"
HEALTH_URL="https://${FUNCTION_APP_NAME}.azurewebsites.net/api/health"
echo "Testing: $HEALTH_URL"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL 2>/dev/null || echo "000")
if [ "$HEALTH_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✅ Health endpoint responding (HTTP 200)${NC}"
elif [ "$HEALTH_RESPONSE" == "000" ]; then
    echo -e "${RED}❌ Cannot reach health endpoint (connection failed)${NC}"
else
    echo -e "${YELLOW}⚠️  Health endpoint returned HTTP $HEALTH_RESPONSE${NC}"
fi
echo ""

echo "💡 Recommendations:"
echo "-------------------"
if [[ $RUNTIME_STATUS != "Running" ]]; then
    echo "- Function App state is '$RUNTIME_STATUS'. Try restarting: az functionapp restart --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP"
fi

if [[ $HEALTH_RESPONSE != "200" ]]; then
    echo "- Function host may not be running. Check Application Insights for detailed errors."
    echo "- Verify Python runtime compatibility with requirements.txt"
    echo "- Consider deploying with: func azure functionapp publish $FUNCTION_APP_NAME --python"
fi

echo ""
echo "📊 Deployment Status Summary:"
echo "==============================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP_NAME"
echo "Runtime Status: $RUNTIME_STATUS"
echo "Health Check: HTTP $HEALTH_RESPONSE"
echo ""
echo "✅ Diagnostic complete!"
