#!/bin/bash

# Vigor Platform - Secrets Management Script
# Handles Azure Key Vault secrets for all environments

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
ENVIRONMENT="dev"
RESOURCE_GROUP=""
KEY_VAULT_NAME=""
FORCE_UPDATE="false"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

show_help() {
    cat << EOF
Vigor Platform - Secrets Management Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV   Environment (dev/staging/prod) [default: dev]
    -g, --resource-group RG Resource group name
    -k, --key-vault NAME    Key vault name
    -f, --force            Force update existing secrets
    -h, --help             Show this help message

Examples:
    $0 --environment dev --resource-group vigor-dev-rg --key-vault vigor-dev-kv
    $0 -e prod -g vigor-prod-rg -k vigor-prod-kv --force

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -k|--key-vault)
            KEY_VAULT_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_UPDATE="true"
            shift
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
if [[ -z "$RESOURCE_GROUP" ]]; then
    log_error "Resource group is required. Use -g or --resource-group"
    exit 1
fi

if [[ -z "$KEY_VAULT_NAME" ]]; then
    log_error "Key vault name is required. Use -k or --key-vault"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod"
    exit 1
fi

log_info "Starting secrets management for environment: $ENVIRONMENT"

# Check Azure CLI login
log_info "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    log_error "Azure CLI not authenticated. Please run 'az login'"
    exit 1
fi

log_success "Azure CLI authenticated"

# Check if Key Vault exists
log_info "Checking Key Vault existence..."
if ! az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    log_error "Key Vault '$KEY_VAULT_NAME' not found in resource group '$RESOURCE_GROUP'"
    exit 1
fi

log_success "Key Vault found: $KEY_VAULT_NAME"

# Function to set secret
set_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"

    # Check if secret exists
    if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$secret_name" &>/dev/null; then
        if [[ "$FORCE_UPDATE" == "false" ]]; then
            log_warning "Secret '$secret_name' already exists. Use --force to update"
            return 0
        else
            log_info "Updating existing secret: $secret_name"
        fi
    else
        log_info "Creating new secret: $secret_name"
    fi

    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "$secret_name" \
        --value "$secret_value" \
        --description "$description" \
        --output none

    log_success "Secret '$secret_name' set successfully"
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -hex 64
}

# Function to generate API key
generate_api_key() {
    echo "vigor_$(openssl rand -hex 16)"
}

log_info "Setting up secrets for $ENVIRONMENT environment..."

# Database secrets
DB_PASSWORD=$(generate_password)
set_secret "database-admin-password" "$DB_PASSWORD" "PostgreSQL administrator password"
set_secret "database-app-password" "$(generate_password)" "PostgreSQL application user password"

# Application secrets
set_secret "jwt-secret-key" "$(generate_jwt_secret)" "JWT signing secret key"
set_secret "app-secret-key" "$(generate_password)" "Application secret key"
set_secret "encryption-key" "$(generate_password)" "Data encryption key"

# API keys
set_secret "openai-api-key" "sk-placeholder-openai-key" "OpenAI API key (update with real key)"
set_secret "azure-openai-api-key" "placeholder-azure-openai-key" "Azure OpenAI API key (update with real key)"

# External service keys
set_secret "sendgrid-api-key" "SG.placeholder-sendgrid-key" "SendGrid API key for email"
set_secret "stripe-secret-key" "sk_test_placeholder" "Stripe secret key for payments"
set_secret "stripe-webhook-secret" "whsec_placeholder" "Stripe webhook endpoint secret"

# Admin credentials
set_secret "admin-email" "admin@vigor.app" "Default admin email"
set_secret "admin-password" "$(generate_password)" "Default admin password"

# Azure specific secrets
set_secret "storage-connection-string" "placeholder-storage-connection" "Azure Storage connection string"
set_secret "application-insights-key" "placeholder-insights-key" "Application Insights instrumentation key"

# Environment specific configurations
case $ENVIRONMENT in
    "dev")
        set_secret "debug-mode" "true" "Enable debug mode"
        set_secret "log-level" "DEBUG" "Application log level"
        set_secret "rate-limit-enabled" "false" "Enable rate limiting"
        ;;
    "staging")
        set_secret "debug-mode" "false" "Enable debug mode"
        set_secret "log-level" "INFO" "Application log level"
        set_secret "rate-limit-enabled" "true" "Enable rate limiting"
        ;;
    "prod")
        set_secret "debug-mode" "false" "Enable debug mode"
        set_secret "log-level" "WARNING" "Application log level"
        set_secret "rate-limit-enabled" "true" "Enable rate limiting"
        set_secret "security-headers-enabled" "true" "Enable security headers"
        set_secret "ssl-redirect" "true" "Force SSL redirect"
        ;;
esac

# LLM Configuration secrets
set_secret "llm-default-provider" "openai" "Default LLM provider"
set_secret "llm-fallback-provider" "azure" "Fallback LLM provider"
set_secret "llm-max-tokens" "4096" "Maximum tokens per request"
set_secret "llm-temperature" "0.7" "Default temperature setting"

# Monitoring and alerting
set_secret "slack-webhook-url" "https://hooks.slack.com/placeholder" "Slack webhook for alerts"
set_secret "pagerduty-integration-key" "placeholder-pagerduty-key" "PagerDuty integration key"

log_success "All secrets configured successfully!"

# Display summary
log_info "Secret management summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Key Vault: $KEY_VAULT_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Secrets created/updated: $(az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "length(@)" -o tsv)"

log_warning "Important reminders:"
echo "  1. Update placeholder API keys with real values"
echo "  2. Secure the generated admin password"
echo "  3. Configure proper access policies for the Key Vault"
echo "  4. Enable audit logging for secret access"

log_success "Secrets management completed successfully!"
