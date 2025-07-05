#!/bin/bash

# Vigor Platform - Infrastructure Health Check Script
# Comprehensive health monitoring for all Azure resources

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
ENVIRONMENT="dev"
RESOURCE_GROUP=""
CHECK_TYPE="full"  # quick, full, deep
OUTPUT_FORMAT="console"  # console, json, html
REPORT_FILE=""

# Health status codes
HEALTH_OK=0
HEALTH_WARNING=1
HEALTH_CRITICAL=2
HEALTH_UNKNOWN=3

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
Vigor Platform - Infrastructure Health Check Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV    Environment (dev/staging/prod) [default: dev]
    -g, --resource-group RG  Resource group name
    -t, --type TYPE         Check type (quick/full/deep) [default: full]
    -f, --format FORMAT     Output format (console/json/html) [default: console]
    -o, --output FILE       Output file for report
    -h, --help              Show this help message

Check Types:
    quick  - Basic connectivity and status checks (2-3 minutes)
    full   - Comprehensive health and performance checks (5-10 minutes)
    deep   - Detailed analysis including logs and metrics (15-20 minutes)

Examples:
    $0 --environment prod --type full
    $0 -e staging -t quick -f json -o health-report.json
    $0 --environment prod --type deep --format html --output health-report.html

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
        -t|--type)
            CHECK_TYPE="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_FILE="$2"
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

# Set default resource group if not provided
if [[ -z "$RESOURCE_GROUP" ]]; then
    RESOURCE_GROUP="vigor-${ENVIRONMENT}-rg"
fi

# Validate parameters
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod"
    exit 1
fi

if [[ ! "$CHECK_TYPE" =~ ^(quick|full|deep)$ ]]; then
    log_error "Check type must be one of: quick, full, deep"
    exit 1
fi

if [[ ! "$OUTPUT_FORMAT" =~ ^(console|json|html)$ ]]; then
    log_error "Output format must be one of: console, json, html"
    exit 1
fi

# Initialize health report
declare -A HEALTH_REPORT
HEALTH_REPORT["timestamp"]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HEALTH_REPORT["environment"]="$ENVIRONMENT"
HEALTH_REPORT["check_type"]="$CHECK_TYPE"
HEALTH_REPORT["overall_status"]="$HEALTH_OK"

# Check Azure CLI authentication
log_info "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    log_error "Azure CLI not authenticated. Please run 'az login'"
    exit 1
fi

log_success "Azure CLI authenticated"

# Function to update overall health status
update_overall_status() {
    local new_status=$1
    if [[ $new_status -gt ${HEALTH_REPORT["overall_status"]} ]]; then
        HEALTH_REPORT["overall_status"]=$new_status
    fi
}

# Function to check resource group
check_resource_group() {
    log_info "Checking resource group: $RESOURCE_GROUP"

    if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["resource_group_status"]=$HEALTH_OK
        HEALTH_REPORT["resource_group_message"]="Resource group exists and accessible"
        log_success "Resource group OK"
    else
        HEALTH_REPORT["resource_group_status"]=$HEALTH_CRITICAL
        HEALTH_REPORT["resource_group_message"]="Resource group not found or inaccessible"
        log_error "Resource group CRITICAL"
        update_overall_status $HEALTH_CRITICAL
        return 1
    fi
}

# Function to check App Service
check_app_service() {
    local app_service="vigor-${ENVIRONMENT}-app"
    log_info "Checking App Service: $app_service"

    # Check if App Service exists
    if ! az webapp show --name "$app_service" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["app_service_status"]=$HEALTH_CRITICAL
        HEALTH_REPORT["app_service_message"]="App Service not found"
        log_error "App Service CRITICAL - not found"
        update_overall_status $HEALTH_CRITICAL
        return 1
    fi

    # Check App Service state
    local state
    state=$(az webapp show --name "$app_service" --resource-group "$RESOURCE_GROUP" --query "state" -o tsv)

    if [[ "$state" == "Running" ]]; then
        HEALTH_REPORT["app_service_status"]=$HEALTH_OK
        HEALTH_REPORT["app_service_message"]="App Service running normally"
        log_success "App Service OK - Running"
    else
        HEALTH_REPORT["app_service_status"]=$HEALTH_WARNING
        HEALTH_REPORT["app_service_message"]="App Service state: $state"
        log_warning "App Service WARNING - State: $state"
        update_overall_status $HEALTH_WARNING
    fi

    # Check application health endpoint (if full or deep check)
    if [[ "$CHECK_TYPE" != "quick" ]]; then
        local app_url
        app_url=$(az webapp show --name "$app_service" --resource-group "$RESOURCE_GROUP" --query "defaultHostName" -o tsv)

        if [[ -n "$app_url" ]]; then
            log_info "Checking application health endpoint..."

            if curl -f -s "https://${app_url}/health" &>/dev/null; then
                HEALTH_REPORT["app_health_status"]=$HEALTH_OK
                HEALTH_REPORT["app_health_message"]="Health endpoint responding"
                log_success "Application health OK"
            else
                HEALTH_REPORT["app_health_status"]=$HEALTH_WARNING
                HEALTH_REPORT["app_health_message"]="Health endpoint not responding"
                log_warning "Application health WARNING"
                update_overall_status $HEALTH_WARNING
            fi
        fi
    fi
}

# Function to check Database
check_database() {
    local db_server="vigor-${ENVIRONMENT}-postgres"
    log_info "Checking Database: $db_server"

    # Check if database server exists
    if ! az postgres server show --name "$db_server" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["database_status"]=$HEALTH_CRITICAL
        HEALTH_REPORT["database_message"]="Database server not found"
        log_error "Database CRITICAL - not found"
        update_overall_status $HEALTH_CRITICAL
        return 1
    fi

    # Check database server state
    local state
    state=$(az postgres server show --name "$db_server" --resource-group "$RESOURCE_GROUP" --query "userVisibleState" -o tsv)

    if [[ "$state" == "Ready" ]]; then
        HEALTH_REPORT["database_status"]=$HEALTH_OK
        HEALTH_REPORT["database_message"]="Database server ready"
        log_success "Database OK - Ready"
    else
        HEALTH_REPORT["database_status"]=$HEALTH_WARNING
        HEALTH_REPORT["database_message"]="Database server state: $state"
        log_warning "Database WARNING - State: $state"
        update_overall_status $HEALTH_WARNING
    fi

    # Check database connectivity (if full or deep check)
    if [[ "$CHECK_TYPE" != "quick" ]]; then
        log_info "Testing database connectivity..."

        # Try to connect using psql (if available)
        if command -v psql &>/dev/null; then
            local key_vault="vigor-${ENVIRONMENT}-kv"
            local db_password

            if db_password=$(az keyvault secret show --vault-name "$key_vault" --name "database-admin-password" --query "value" -o tsv 2>/dev/null); then
                if PGPASSWORD="$db_password" psql \
                    -h "${db_server}.postgres.database.azure.com" \
                    -U "vigoradmin@${db_server}" \
                    -d "vigor" \
                    -c "SELECT 1;" &>/dev/null; then

                    HEALTH_REPORT["database_connectivity_status"]=$HEALTH_OK
                    HEALTH_REPORT["database_connectivity_message"]="Database connection successful"
                    log_success "Database connectivity OK"
                else
                    HEALTH_REPORT["database_connectivity_status"]=$HEALTH_WARNING
                    HEALTH_REPORT["database_connectivity_message"]="Database connection failed"
                    log_warning "Database connectivity WARNING"
                    update_overall_status $HEALTH_WARNING
                fi
            else
                HEALTH_REPORT["database_connectivity_status"]=$HEALTH_WARNING
                HEALTH_REPORT["database_connectivity_message"]="Cannot retrieve database password"
                log_warning "Database connectivity WARNING - password retrieval failed"
                update_overall_status $HEALTH_WARNING
            fi
        else
            HEALTH_REPORT["database_connectivity_status"]=$HEALTH_UNKNOWN
            HEALTH_REPORT["database_connectivity_message"]="psql not available for connectivity test"
            log_info "Database connectivity UNKNOWN - psql not available"
        fi
    fi
}

# Function to check Storage Account
check_storage() {
    local storage_account="vigor${ENVIRONMENT}storage"
    log_info "Checking Storage Account: $storage_account"

    # Check if storage account exists
    if ! az storage account show --name "$storage_account" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["storage_status"]=$HEALTH_CRITICAL
        HEALTH_REPORT["storage_message"]="Storage account not found"
        log_error "Storage CRITICAL - not found"
        update_overall_status $HEALTH_CRITICAL
        return 1
    fi

    # Check storage account provisioning state
    local state
    state=$(az storage account show --name "$storage_account" --resource-group "$RESOURCE_GROUP" --query "provisioningState" -o tsv)

    if [[ "$state" == "Succeeded" ]]; then
        HEALTH_REPORT["storage_status"]=$HEALTH_OK
        HEALTH_REPORT["storage_message"]="Storage account provisioned successfully"
        log_success "Storage OK"
    else
        HEALTH_REPORT["storage_status"]=$HEALTH_WARNING
        HEALTH_REPORT["storage_message"]="Storage account state: $state"
        log_warning "Storage WARNING - State: $state"
        update_overall_status $HEALTH_WARNING
    fi
}

# Function to check Key Vault
check_key_vault() {
    local key_vault="vigor-${ENVIRONMENT}-kv"
    log_info "Checking Key Vault: $key_vault"

    # Check if Key Vault exists
    if ! az keyvault show --name "$key_vault" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["keyvault_status"]=$HEALTH_CRITICAL
        HEALTH_REPORT["keyvault_message"]="Key Vault not found"
        log_error "Key Vault CRITICAL - not found"
        update_overall_status $HEALTH_CRITICAL
        return 1
    fi

    # Check Key Vault provisioning state
    local state
    state=$(az keyvault show --name "$key_vault" --resource-group "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv)

    if [[ "$state" == "Succeeded" ]]; then
        HEALTH_REPORT["keyvault_status"]=$HEALTH_OK
        HEALTH_REPORT["keyvault_message"]="Key Vault accessible"
        log_success "Key Vault OK"
    else
        HEALTH_REPORT["keyvault_status"]=$HEALTH_WARNING
        HEALTH_REPORT["keyvault_message"]="Key Vault state: $state"
        log_warning "Key Vault WARNING - State: $state"
        update_overall_status $HEALTH_WARNING
    fi

    # Check secret access (if full or deep check)
    if [[ "$CHECK_TYPE" != "quick" ]]; then
        log_info "Testing Key Vault secret access..."

        if az keyvault secret list --vault-name "$key_vault" --query "length(@)" -o tsv &>/dev/null; then
            HEALTH_REPORT["keyvault_access_status"]=$HEALTH_OK
            HEALTH_REPORT["keyvault_access_message"]="Secret access working"
            log_success "Key Vault access OK"
        else
            HEALTH_REPORT["keyvault_access_status"]=$HEALTH_WARNING
            HEALTH_REPORT["keyvault_access_message"]="Cannot access secrets"
            log_warning "Key Vault access WARNING"
            update_overall_status $HEALTH_WARNING
        fi
    fi
}

# Function to check Application Insights
check_application_insights() {
    local insights_name="vigor-${ENVIRONMENT}-insights"
    log_info "Checking Application Insights: $insights_name"

    # Check if Application Insights exists
    if ! az monitor app-insights component show --app "$insights_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        HEALTH_REPORT["insights_status"]=$HEALTH_WARNING
        HEALTH_REPORT["insights_message"]="Application Insights not found"
        log_warning "Application Insights WARNING - not found"
        update_overall_status $HEALTH_WARNING
        return 1
    fi

    HEALTH_REPORT["insights_status"]=$HEALTH_OK
    HEALTH_REPORT["insights_message"]="Application Insights available"
    log_success "Application Insights OK"
}

# Function to check performance metrics (deep check only)
check_performance_metrics() {
    if [[ "$CHECK_TYPE" != "deep" ]]; then
        return 0
    fi

    log_info "Analyzing performance metrics (last hour)..."

    local app_service="vigor-${ENVIRONMENT}-app"
    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local start_time=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")

    # Get CPU metrics
    local cpu_avg
    cpu_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_service}" \
        --metric "CpuPercentage" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    # Evaluate CPU performance
    if (( $(echo "$cpu_avg > 80" | bc -l) )); then
        HEALTH_REPORT["performance_status"]=$HEALTH_WARNING
        HEALTH_REPORT["performance_message"]="High CPU usage: ${cpu_avg}%"
        log_warning "Performance WARNING - High CPU: ${cpu_avg}%"
        update_overall_status $HEALTH_WARNING
    elif (( $(echo "$cpu_avg > 60" | bc -l) )); then
        HEALTH_REPORT["performance_status"]=$HEALTH_WARNING
        HEALTH_REPORT["performance_message"]="Moderate CPU usage: ${cpu_avg}%"
        log_warning "Performance WARNING - Moderate CPU: ${cpu_avg}%"
    else
        HEALTH_REPORT["performance_status"]=$HEALTH_OK
        HEALTH_REPORT["performance_message"]="CPU usage normal: ${cpu_avg}%"
        log_success "Performance OK - CPU: ${cpu_avg}%"
    fi

    HEALTH_REPORT["cpu_usage"]="$cpu_avg"
}

# Function to generate report
generate_report() {
    local overall_status_text
    case ${HEALTH_REPORT["overall_status"]} in
        $HEALTH_OK)
            overall_status_text="HEALTHY"
            ;;
        $HEALTH_WARNING)
            overall_status_text="WARNING"
            ;;
        $HEALTH_CRITICAL)
            overall_status_text="CRITICAL"
            ;;
        *)
            overall_status_text="UNKNOWN"
            ;;
    esac

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        # Generate JSON report
        local json_report="{"
        json_report+="\"timestamp\":\"${HEALTH_REPORT["timestamp"]}\","
        json_report+="\"environment\":\"${HEALTH_REPORT["environment"]}\","
        json_report+="\"check_type\":\"${HEALTH_REPORT["check_type"]}\","
        json_report+="\"overall_status\":\"$overall_status_text\","
        json_report+="\"details\":{"

        for key in "${!HEALTH_REPORT[@]}"; do
            if [[ "$key" != "timestamp" && "$key" != "environment" && "$key" != "check_type" && "$key" != "overall_status" ]]; then
                json_report+="\"$key\":\"${HEALTH_REPORT[$key]}\","
            fi
        done

        json_report="${json_report%,}"  # Remove last comma
        json_report+="}}"

        if [[ -n "$REPORT_FILE" ]]; then
            echo "$json_report" | jq '.' > "$REPORT_FILE"
            log_success "JSON report saved to: $REPORT_FILE"
        else
            echo "$json_report" | jq '.'
        fi

    elif [[ "$OUTPUT_FORMAT" == "html" ]]; then
        # Generate HTML report
        local html_report="<!DOCTYPE html>
<html>
<head>
    <title>Vigor Platform Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .healthy { color: green; }
        .warning { color: orange; }
        .critical { color: red; }
        .unknown { color: gray; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Vigor Platform Health Report</h1>
    <p><strong>Environment:</strong> ${HEALTH_REPORT["environment"]}</p>
    <p><strong>Check Type:</strong> ${HEALTH_REPORT["check_type"]}</p>
    <p><strong>Timestamp:</strong> ${HEALTH_REPORT["timestamp"]}</p>
    <p><strong>Overall Status:</strong> <span class=\"$(echo $overall_status_text | tr '[:upper:]' '[:lower:]')\">$overall_status_text</span></p>

    <h2>Component Details</h2>
    <table>
        <tr><th>Component</th><th>Status</th><th>Message</th></tr>"

        for key in "${!HEALTH_REPORT[@]}"; do
            if [[ "$key" =~ _status$ ]]; then
                local component="${key%_status}"
                local message_key="${component}_message"
                local status_text

                case ${HEALTH_REPORT[$key]} in
                    $HEALTH_OK) status_text="<span class=\"healthy\">OK</span>" ;;
                    $HEALTH_WARNING) status_text="<span class=\"warning\">WARNING</span>" ;;
                    $HEALTH_CRITICAL) status_text="<span class=\"critical\">CRITICAL</span>" ;;
                    *) status_text="<span class=\"unknown\">UNKNOWN</span>" ;;
                esac

                html_report+="<tr><td>$component</td><td>$status_text</td><td>${HEALTH_REPORT[$message_key]:-N/A}</td></tr>"
            fi
        done

        html_report+="</table></body></html>"

        if [[ -n "$REPORT_FILE" ]]; then
            echo "$html_report" > "$REPORT_FILE"
            log_success "HTML report saved to: $REPORT_FILE"
        else
            echo "$html_report"
        fi

    else
        # Console output
        echo ""
        echo "===================================="
        echo "  VIGOR PLATFORM HEALTH REPORT"
        echo "===================================="
        echo "Environment: ${HEALTH_REPORT["environment"]}"
        echo "Check Type: ${HEALTH_REPORT["check_type"]}"
        echo "Timestamp: ${HEALTH_REPORT["timestamp"]}"
        echo "Overall Status: $overall_status_text"
        echo ""
        echo "Component Details:"
        echo "------------------------------------"

        for key in "${!HEALTH_REPORT[@]}"; do
            if [[ "$key" =~ _status$ ]]; then
                local component="${key%_status}"
                local message_key="${component}_message"
                local status_text

                case ${HEALTH_REPORT[$key]} in
                    $HEALTH_OK) status_text="OK" ;;
                    $HEALTH_WARNING) status_text="WARNING" ;;
                    $HEALTH_CRITICAL) status_text="CRITICAL" ;;
                    *) status_text="UNKNOWN" ;;
                esac

                printf "%-20s: %-10s %s\n" "$component" "$status_text" "${HEALTH_REPORT[$message_key]:-N/A}"
            fi
        done

        echo "===================================="

        if [[ -n "$REPORT_FILE" ]]; then
            generate_report > "$REPORT_FILE"
            log_success "Console report saved to: $REPORT_FILE"
        fi
    fi
}

# Main execution
log_info "Starting $CHECK_TYPE health check for $ENVIRONMENT environment..."

# Run health checks
check_resource_group
check_app_service
check_database
check_storage
check_key_vault
check_application_insights
check_performance_metrics

# Generate and display report
generate_report

# Exit with appropriate code
exit ${HEALTH_REPORT["overall_status"]}
