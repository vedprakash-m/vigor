#!/bin/bash
# Azure App Service Staging Slot Setup Script
# Run this script to prepare for the new DAG-based CI/CD pipeline

set -e

echo "🚀 Setting up Azure App Service staging slot for DAG CI/CD pipeline..."

# Configuration
RESOURCE_GROUP="vigor-rg"
APP_NAME="vigor-backend"
SLOT_NAME="staging"

# Check if Azure CLI is logged in
if ! az account show &>/dev/null; then
    echo "❌ Please log in to Azure CLI first: az login"
    exit 1
fi

echo "✅ Azure CLI authenticated"

# Check if app service exists
if ! az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "❌ App Service '$APP_NAME' not found in resource group '$RESOURCE_GROUP'"
    echo "Please ensure the app service exists before creating slots"
    exit 1
fi

echo "✅ App Service '$APP_NAME' found"

# Check if staging slot already exists
if az webapp deployment slot show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --slot "$SLOT_NAME" &>/dev/null; then
    echo "✅ Staging slot already exists"
else
    echo "📦 Creating staging deployment slot..."
    az webapp deployment slot create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --slot "$SLOT_NAME"
    echo "✅ Staging slot created successfully"
fi

# Configure staging slot settings
echo "⚙️ Configuring staging slot settings..."
az webapp config appsettings set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --slot "$SLOT_NAME" \
    --settings \
    ENVIRONMENT=staging \
    DEBUG=true \
    WEBSITE_SLOT_NAME=staging

echo "✅ Staging slot configuration complete"

# Display slot information
echo ""
echo "📋 Staging Slot Information:"
echo "   • Name: $APP_NAME-$SLOT_NAME"
echo "   • URL: https://$APP_NAME-$SLOT_NAME.azurewebsites.net"
echo "   • Resource Group: $RESOURCE_GROUP"
echo ""
echo "🎯 Next steps:"
echo "   1. Configure GitHub environments (staging, production)"
echo "   2. Test the new CI/CD pipeline with a small change"
echo "   3. Verify staging deployment works"
echo "   4. Remove old CI workflows after validation"
echo ""
echo "✅ Azure setup complete! Ready for DAG CI/CD pipeline migration."
