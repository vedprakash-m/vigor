#!/bin/bash

# Vigor Modernized Infrastructure Deployment Script
# Single Resource Group Architecture with Azure Functions + Cosmos DB

set -e

# Configuration
RESOURCE_GROUP="vigor-rg"
LOCATION="Central US"
DEPLOYMENT_NAME="vigor-modernized-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="main-modernized.bicep"
PARAMETERS_FILE="parameters-modernized.bicepparam"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Vigor Modernized Infrastructure Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    echo -e "${RED}ERROR: Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}ERROR: Not logged in to Azure. Please run 'az login'${NC}"
    exit 1
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${BLUE}Current subscription:${NC} $SUBSCRIPTION"
echo ""

# Check if resource group exists, create if not
echo -e "${YELLOW}Checking resource group...${NC}"
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
    az group create --name $RESOURCE_GROUP --location "$LOCATION"
    echo -e "${GREEN}✓ Resource group created${NC}"
else
    echo -e "${GREEN}✓ Resource group exists${NC}"
fi
echo ""

# Validate the Bicep template
echo -e "${YELLOW}Validating Bicep template...${NC}"
if az deployment group validate \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAMETERS_FILE &> /dev/null; then
    echo -e "${GREEN}✓ Template validation successful${NC}"
else
    echo -e "${RED}✗ Template validation failed${NC}"
    echo "Running validation with verbose output..."
    az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file $TEMPLATE_FILE \
        --parameters $PARAMETERS_FILE
    exit 1
fi
echo ""

# Deploy the infrastructure
echo -e "${YELLOW}Deploying infrastructure...${NC}"
echo -e "${BLUE}Deployment name:${NC} $DEPLOYMENT_NAME"
echo -e "${BLUE}Resource group:${NC} $RESOURCE_GROUP"
echo -e "${BLUE}Template:${NC} $TEMPLATE_FILE"
echo ""

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAMETERS_FILE \
    --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✓ Deployment Completed Successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Get outputs
    echo -e "${YELLOW}Deployment outputs:${NC}"
    az deployment group show \
        --resource-group $RESOURCE_GROUP \
        --name $DEPLOYMENT_NAME \
        --query properties.outputs \
        --output table
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Update GitHub secrets with new infrastructure details"
    echo "2. Deploy Function App code using CI/CD pipeline"
    echo "3. Configure Static Web App with GitHub repository"
    echo "4. Run post-deployment verification tests"
    
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
