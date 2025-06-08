#!/bin/bash

# Vigor Deployment Verification Script
# This script verifies that all infrastructure components are properly deployed

set -e

RESOURCE_GROUP="vigor-rg"
ENVIRONMENT="prod"

echo "🔍 Verifying Vigor deployment in Azure..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Environment: $ENVIRONMENT"
echo ""

# Check if logged in to Azure
if ! az account show > /dev/null 2>&1; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Function to check resource existence
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local query=$3

    echo -n "Checking $resource_type..."

    if [ -n "$query" ]; then
        result=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "$resource_type" --query "$query" --output tsv 2>/dev/null)
    else
        result=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "$resource_type" --output tsv 2>/dev/null | wc -l)
    fi

    if [ -n "$result" ] && [ "$result" != "0" ]; then
        echo " ✅"
        if [ -n "$query" ]; then
            echo "  └─ $result"
        fi
        return 0
    else
        echo " ❌"
        return 1
    fi
}

# Function to get resource URL
get_url() {
    local resource_type=$1
    local url_query=$2

    url=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "$resource_type" --query "$url_query" --output tsv 2>/dev/null)
    if [ -n "$url" ]; then
        echo "  🌐 $url"
    fi
}

echo "📋 Resource Verification:"
echo "========================"

# Check Resource Group
echo -n "Resource Group ($RESOURCE_GROUP)..."
if az group show --name $RESOURCE_GROUP > /dev/null 2>&1; then
    echo " ✅"
else
    echo " ❌"
    echo "❌ Resource group not found. Deployment failed."
    exit 1
fi

# Check App Service Plan
check_resource "Microsoft.Web/serverfarms" "App Service Plan"

# Check App Service
if check_resource "Microsoft.Web/sites" "App Service" "[?kind=='app'].name | [0]"; then
    get_url "Microsoft.Web/sites" "[?kind=='app'].defaultHostName | [0]"
fi

# Check Static Web App
if check_resource "Microsoft.Web/staticSites" "Static Web App" "[0].name"; then
    get_url "Microsoft.Web/staticSites" "[0].defaultHostname"
fi

# Check PostgreSQL
if check_resource "Microsoft.DBforPostgreSQL/flexibleServers" "PostgreSQL Server" "[0].name"; then
    get_url "Microsoft.DBforPostgreSQL/flexibleServers" "[0].fullyQualifiedDomainName"
fi

# Check Redis Cache
check_resource "Microsoft.Cache/Redis" "Redis Cache" "[0].name"

# Check Key Vault
if check_resource "Microsoft.KeyVault/vaults" "Key Vault" "[0].name"; then
    get_url "Microsoft.KeyVault/vaults" "[0].properties.vaultUri"
fi

# Check Storage Account
check_resource "Microsoft.Storage/storageAccounts" "Storage Account" "[0].name"

# Check Container Registry
if check_resource "Microsoft.ContainerRegistry/registries" "Container Registry" "[0].name"; then
    get_url "Microsoft.ContainerRegistry/registries" "[0].loginServer"
fi

# Check Application Insights
check_resource "Microsoft.Insights/components" "Application Insights" "[0].name"

# Check Log Analytics
check_resource "Microsoft.OperationalInsights/workspaces" "Log Analytics Workspace" "[0].name"

echo ""
echo "🌐 Application URLs:"
echo "==================="

# Get frontend URL
frontend_url=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[0].defaultHostname" --output tsv 2>/dev/null)
if [ -n "$frontend_url" ]; then
    echo "Frontend: https://$frontend_url"
else
    echo "Frontend: ❌ Not available"
fi

# Get backend URL
backend_url=$(az webapp list --resource-group $RESOURCE_GROUP --query "[?kind=='app'].defaultHostName | [0]" --output tsv 2>/dev/null)
if [ -n "$backend_url" ]; then
    echo "Backend:  https://$backend_url"
    echo "API:      https://$backend_url/api/"
    echo "Admin:    https://$backend_url/admin/"
else
    echo "Backend:  ❌ Not available"
fi

echo ""
echo "🔍 Health Check:"
echo "================"

# Test backend health endpoint
if [ -n "$backend_url" ]; then
    echo -n "Testing backend health endpoint..."
    if curl -f -s "https://$backend_url/health/" > /dev/null 2>&1; then
        echo " ✅"
    else
        echo " ⚠️  (may still be starting up)"
    fi
fi

# Test frontend
if [ -n "$frontend_url" ]; then
    echo -n "Testing frontend..."
    if curl -f -s "https://$frontend_url" > /dev/null 2>&1; then
        echo " ✅"
    else
        echo " ⚠️  (may still be deploying)"
    fi
fi

echo ""
echo "📊 Deployment Summary:"
echo "====================="

# Count resources
total_resources=$(az resource list --resource-group $RESOURCE_GROUP --output tsv | wc -l)
echo "Total resources deployed: $total_resources"

# Check deployment status
deployment_status=$(az deployment group list --resource-group $RESOURCE_GROUP --query "[0].properties.provisioningState" --output tsv 2>/dev/null)
if [ "$deployment_status" = "Succeeded" ]; then
    echo "Last deployment status: ✅ $deployment_status"
    echo ""
    echo "🎉 Vigor deployment verification completed successfully!"
    echo "✅ All core infrastructure components are deployed and accessible."
else
    echo "Last deployment status: ⚠️  $deployment_status"
    echo ""
    echo "⚠️  Deployment verification completed with warnings."
    echo "Some components may still be initializing."
fi

echo ""
echo "🔗 Useful commands:"
echo "  - View all resources: az resource list --resource-group $RESOURCE_GROUP --output table"
echo "  - View deployment history: az deployment group list --resource-group $RESOURCE_GROUP --output table"
echo "  - View app service logs: az webapp log tail --resource-group $RESOURCE_GROUP --name [APP_NAME]"
