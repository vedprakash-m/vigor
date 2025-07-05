#!/bin/bash

# Vigor Platform - Azure Deployment Script
# Automated deployment for dev/staging/prod environments

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
ENVIRONMENT="dev"
LOCATION="East US"
RESOURCE_GROUP=""
SUBSCRIPTION_ID=""
CONTAINER_TAG="latest"
ADMIN_LOGIN=""
ADMIN_PASSWORD=""
CUSTOM_DOMAIN=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Vigor Platform - Azure Deployment Script

Usage: $0 [OPTIONS]

OPTIONS:
    -e, --environment    Environment name (dev|staging|prod) [default: dev]
    -l, --location       Azure location [default: "East US"]
    -g, --resource-group Resource group name [required]
    -s, --subscription   Azure subscription ID [required]
    -t, --tag           Container image tag [default: latest]
    -u, --admin-user    PostgreSQL admin username [required]
    -p, --admin-pass    PostgreSQL admin password [required]
    -d, --domain        Custom domain name [optional]
    -h, --help          Show this help message

EXAMPLES:
    # Deploy to development environment
    $0 -e dev -g vigor-dev-rg -s xxxx-xxxx-xxxx -u admin -p SecurePass123!

    # Deploy to production with custom domain
    $0 -e prod -g vigor-prod-rg -s xxxx-xxxx-xxxx -u admin -p SecurePass123! -d vigor.fitness

PREREQUISITES:
    - Azure CLI installed and logged in
    - Docker installed (for building images)
    - Appropriate Azure permissions for resource creation

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -t|--tag)
            CONTAINER_TAG="$2"
            shift 2
            ;;
        -u|--admin-user)
            ADMIN_LOGIN="$2"
            shift 2
            ;;
        -p|--admin-pass)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -d|--domain)
            CUSTOM_DOMAIN="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP" || -z "$SUBSCRIPTION_ID" || -z "$ADMIN_LOGIN" || -z "$ADMIN_PASSWORD" ]]; then
    log_error "Missing required parameters"
    show_help
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be dev, staging, or prod"
    exit 1
fi

# Set deployment name with timestamp
DEPLOYMENT_NAME="vigor-deployment-$(date +%Y%m%d-%H%M%S)"

log_info "Starting Vigor Platform deployment..."
log_info "Environment: $ENVIRONMENT"
log_info "Location: $LOCATION"
log_info "Resource Group: $RESOURCE_GROUP"
log_info "Container Tag: $CONTAINER_TAG"

# Check Azure CLI login
log_info "Checking Azure CLI authentication..."
if ! az account show > /dev/null 2>&1; then
    log_error "Azure CLI not authenticated. Please run 'az login'"
    exit 1
fi

# Set subscription
log_info "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
log_info "Creating resource group if it doesn't exist..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Deploy ARM template
log_info "Deploying Azure infrastructure..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$SCRIPT_DIR/vigor-infrastructure.json" \
    --parameters \
        environment="$ENVIRONMENT" \
        location="$LOCATION" \
        administratorLogin="$ADMIN_LOGIN" \
        administratorPassword="$ADMIN_PASSWORD" \
        containerImageTag="$CONTAINER_TAG" \
        customDomainName="$CUSTOM_DOMAIN" \
    --name "$DEPLOYMENT_NAME" \
    --output json)

if [[ $? -ne 0 ]]; then
    log_error "ARM template deployment failed"
    exit 1
fi

log_success "Infrastructure deployment completed successfully"

# Extract outputs from deployment
WEB_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.webAppUrl.value')
CDN_ENDPOINT_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.cdnEndpointUrl.value')
DATABASE_CONNECTION=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.databaseConnectionString.value')
INSIGHTS_KEY=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.applicationInsightsInstrumentationKey.value')
KEY_VAULT_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.keyVaultUrl.value')
CONTAINER_REGISTRY_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.containerRegistryUrl.value')

# Build and push container image
log_info "Building and pushing container image..."
cd "$PROJECT_ROOT"

# Build the container
docker build -t "vigor:$CONTAINER_TAG" -f backend/Dockerfile .

# Tag for Azure Container Registry
docker tag "vigor:$CONTAINER_TAG" "$CONTAINER_REGISTRY_URL/vigor:$CONTAINER_TAG"

# Login to Azure Container Registry
az acr login --name "$(echo $CONTAINER_REGISTRY_URL | cut -d'.' -f1)"

# Push image
docker push "$CONTAINER_REGISTRY_URL/vigor:$CONTAINER_TAG"

log_success "Container image pushed successfully"

# Wait for App Service to update
log_info "Waiting for App Service to deploy new container..."
sleep 30

# Restart App Service to ensure new container is loaded
APP_NAME="vigor-${ENVIRONMENT}-app"
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"

# Health check
log_info "Performing health check..."
sleep 15

HEALTH_CHECK_URL="${WEB_APP_URL}/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL" || echo "000")

if [[ "$HTTP_STATUS" == "200" ]]; then
    log_success "Health check passed"
else
    log_warning "Health check failed (HTTP $HTTP_STATUS). App may still be starting up."
fi

# Store secrets in Key Vault
log_info "Storing configuration secrets in Key Vault..."
VAULT_NAME="vigor-${ENVIRONMENT}-kv-$(echo $KEY_VAULT_URL | grep -o '[^/]*' | tail -1 | cut -d'.' -f1)"

# Get current user object ID for Key Vault access
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Grant Key Vault access to current user
az keyvault set-policy \
    --name "$VAULT_NAME" \
    --object-id "$USER_OBJECT_ID" \
    --secret-permissions get list set delete

# Store secrets
az keyvault secret set --vault-name "$VAULT_NAME" --name "database-connection-string" --value "$DATABASE_CONNECTION"
az keyvault secret set --vault-name "$VAULT_NAME" --name "application-insights-key" --value "$INSIGHTS_KEY"

log_success "Configuration secrets stored in Key Vault"

# Display deployment summary
cat << EOF

${GREEN}=== DEPLOYMENT COMPLETED SUCCESSFULLY ===${NC}

Environment: $ENVIRONMENT
Deployment Name: $DEPLOYMENT_NAME

${BLUE}URLs:${NC}
- Web Application: $WEB_APP_URL
- CDN Endpoint: $CDN_ENDPOINT_URL
- Health Check: ${WEB_APP_URL}/health

${BLUE}Azure Resources:${NC}
- Resource Group: $RESOURCE_GROUP
- Container Registry: $CONTAINER_REGISTRY_URL
- Key Vault: $KEY_VAULT_URL

${BLUE}Next Steps:${NC}
1. Verify application is running: curl $HEALTH_CHECK_URL
2. Configure custom domain if needed
3. Set up monitoring alerts
4. Configure backup policies
5. Review security configurations

${YELLOW}Important:${NC}
- Database credentials are stored in Key Vault
- Application Insights is configured for monitoring
- CDN is set up for static asset caching
- Health checks are configured at /health endpoint

EOF

log_success "Vigor Platform deployment completed successfully!"
