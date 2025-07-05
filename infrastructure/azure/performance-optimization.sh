#!/bin/bash

# Vigor Platform - Performance Optimization and Scaling Script
# Automated performance tuning and scaling configuration

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
ENVIRONMENT="dev"
RESOURCE_GROUP=""
APP_SERVICE=""
DATABASE_SERVER=""
OPERATION="analyze"  # analyze, optimize, scale-up, scale-down

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
Vigor Platform - Performance Optimization and Scaling Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV       Environment (dev/staging/prod) [default: dev]
    -g, --resource-group RG     Resource group name
    -a, --app-service APP       App service name
    -d, --database-server DB    Database server name
    -o, --operation OP          Operation (analyze/optimize/scale-up/scale-down) [default: analyze]
    -h, --help                  Show this help message

Operations:
    analyze     - Analyze current performance metrics and recommendations
    optimize    - Apply performance optimizations
    scale-up    - Scale resources up based on load
    scale-down  - Scale resources down to save costs

Examples:
    $0 --environment prod --operation analyze
    $0 -e staging -o optimize
    $0 --environment prod --operation scale-up

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
        -a|--app-service)
            APP_SERVICE="$2"
            shift 2
            ;;
        -d|--database-server)
            DATABASE_SERVER="$2"
            shift 2
            ;;
        -o|--operation)
            OPERATION="$2"
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

# Set default resource names if not provided
if [[ -z "$RESOURCE_GROUP" ]]; then
    RESOURCE_GROUP="vigor-${ENVIRONMENT}-rg"
fi

if [[ -z "$APP_SERVICE" ]]; then
    APP_SERVICE="vigor-${ENVIRONMENT}-app"
fi

if [[ -z "$DATABASE_SERVER" ]]; then
    DATABASE_SERVER="vigor-${ENVIRONMENT}-postgres"
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod"
    exit 1
fi

# Validate operation
if [[ ! "$OPERATION" =~ ^(analyze|optimize|scale-up|scale-down)$ ]]; then
    log_error "Operation must be one of: analyze, optimize, scale-up, scale-down"
    exit 1
fi

log_info "Starting performance operations for environment: $ENVIRONMENT"

# Check Azure CLI login
log_info "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    log_error "Azure CLI not authenticated. Please run 'az login'"
    exit 1
fi

log_success "Azure CLI authenticated"

# Function to get performance metrics
get_performance_metrics() {
    log_info "Gathering performance metrics..."

    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local start_time=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")

    # App Service metrics
    log_info "Gathering App Service metrics..."
    local cpu_avg memory_avg response_time_avg requests_total

    cpu_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE}" \
        --metric "CpuPercentage" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    memory_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE}" \
        --metric "MemoryPercentage" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    response_time_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE}" \
        --metric "AverageResponseTime" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    requests_total=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE}" \
        --metric "Requests" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Total \
        --query "value[0].timeseries[0].data[-1].total" -o tsv 2>/dev/null || echo "0")

    # Database metrics
    log_info "Gathering Database metrics..."
    local db_cpu_avg db_memory_avg db_connections_avg

    db_cpu_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DBforPostgreSQL/servers/${DATABASE_SERVER}" \
        --metric "cpu_percent" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    db_memory_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DBforPostgreSQL/servers/${DATABASE_SERVER}" \
        --metric "memory_percent" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    db_connections_avg=$(az monitor metrics list \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DBforPostgreSQL/servers/${DATABASE_SERVER}" \
        --metric "active_connections" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null || echo "0")

    # Display metrics
    echo ""
    echo "=== PERFORMANCE METRICS (Last Hour) ==="
    echo ""
    echo "App Service ($APP_SERVICE):"
    echo "  CPU Usage: ${cpu_avg}%"
    echo "  Memory Usage: ${memory_avg}%"
    echo "  Average Response Time: ${response_time_avg}s"
    echo "  Total Requests: ${requests_total}"
    echo ""
    echo "Database ($DATABASE_SERVER):"
    echo "  CPU Usage: ${db_cpu_avg}%"
    echo "  Memory Usage: ${db_memory_avg}%"
    echo "  Active Connections: ${db_connections_avg}"
    echo ""

    # Store metrics for use in other functions
    export CURRENT_CPU_AVG="$cpu_avg"
    export CURRENT_MEMORY_AVG="$memory_avg"
    export CURRENT_RESPONSE_TIME="$response_time_avg"
    export CURRENT_DB_CPU="$db_cpu_avg"
    export CURRENT_DB_MEMORY="$db_memory_avg"
}

# Function to analyze performance and provide recommendations
analyze_performance() {
    log_info "Analyzing performance and generating recommendations..."

    get_performance_metrics

    echo "=== PERFORMANCE ANALYSIS ==="
    echo ""

    # CPU Analysis
    if (( $(echo "$CURRENT_CPU_AVG > 80" | bc -l) )); then
        echo "🔴 HIGH CPU USAGE (${CURRENT_CPU_AVG}%)"
        echo "   Recommendations:"
        echo "   - Scale up to higher tier (P1V2 → P2V2 or P3V2)"
        echo "   - Enable auto-scaling"
        echo "   - Review application code for CPU-intensive operations"
    elif (( $(echo "$CURRENT_CPU_AVG > 60" | bc -l) )); then
        echo "🟡 MODERATE CPU USAGE (${CURRENT_CPU_AVG}%)"
        echo "   Recommendations:"
        echo "   - Monitor trends and consider scaling if sustained"
        echo "   - Enable auto-scaling for peak handling"
    else
        echo "🟢 GOOD CPU USAGE (${CURRENT_CPU_AVG}%)"
    fi

    # Memory Analysis
    if (( $(echo "$CURRENT_MEMORY_AVG > 85" | bc -l) )); then
        echo "🔴 HIGH MEMORY USAGE (${CURRENT_MEMORY_AVG}%)"
        echo "   Recommendations:"
        echo "   - Scale up to higher memory tier"
        echo "   - Review memory leaks in application"
        echo "   - Optimize database queries and caching"
    elif (( $(echo "$CURRENT_MEMORY_AVG > 70" | bc -l) )); then
        echo "🟡 MODERATE MEMORY USAGE (${CURRENT_MEMORY_AVG}%)"
        echo "   Recommendations:"
        echo "   - Monitor for memory leaks"
        echo "   - Consider adding Redis cache"
    else
        echo "🟢 GOOD MEMORY USAGE (${CURRENT_MEMORY_AVG}%)"
    fi

    # Response Time Analysis
    if (( $(echo "$CURRENT_RESPONSE_TIME > 3" | bc -l) )); then
        echo "🔴 HIGH RESPONSE TIME (${CURRENT_RESPONSE_TIME}s)"
        echo "   Recommendations:"
        echo "   - Enable CDN for static content"
        echo "   - Optimize database queries"
        echo "   - Implement caching strategy"
        echo "   - Consider database scaling"
    elif (( $(echo "$CURRENT_RESPONSE_TIME > 1" | bc -l) )); then
        echo "🟡 MODERATE RESPONSE TIME (${CURRENT_RESPONSE_TIME}s)"
        echo "   Recommendations:"
        echo "   - Monitor database performance"
        echo "   - Consider implementing caching"
    else
        echo "🟢 GOOD RESPONSE TIME (${CURRENT_RESPONSE_TIME}s)"
    fi

    # Database Analysis
    if (( $(echo "$CURRENT_DB_CPU > 80" | bc -l) )); then
        echo "🔴 HIGH DATABASE CPU (${CURRENT_DB_CPU}%)"
        echo "   Recommendations:"
        echo "   - Scale database to higher tier"
        echo "   - Optimize queries and add indexes"
        echo "   - Consider read replicas"
    fi

    if (( $(echo "$CURRENT_DB_MEMORY > 85" | bc -l) )); then
        echo "🔴 HIGH DATABASE MEMORY (${CURRENT_DB_MEMORY}%)"
        echo "   Recommendations:"
        echo "   - Scale database memory"
        echo "   - Optimize buffer pool settings"
        echo "   - Review query complexity"
    fi

    echo ""
}

# Function to apply performance optimizations
optimize_performance() {
    log_info "Applying performance optimizations..."

    # App Service optimizations
    log_info "Optimizing App Service configuration..."

    # Enable Always On for non-development environments
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        az webapp config set \
            --name "$APP_SERVICE" \
            --resource-group "$RESOURCE_GROUP" \
            --always-on true \
            --output none
        log_success "Enabled Always On"
    fi

    # Configure connection strings for optimal performance
    az webapp config connection-string set \
        --name "$APP_SERVICE" \
        --resource-group "$RESOURCE_GROUP" \
        --connection-string-type PostgreSQL \
        --settings "DefaultConnection=Server=${DATABASE_SERVER}.postgres.database.azure.com;Database=vigor;Port=5432;SSL Mode=Require;Trust Server Certificate=true;Pooling=true;Min Pool Size=5;Max Pool Size=100;Connection Lifetime=300;" \
        --output none

    # Set performance-related app settings
    az webapp config appsettings set \
        --name "$APP_SERVICE" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" \
            "WEBSITE_DYNAMIC_CACHE=1" \
            "WEBSITE_LOCAL_CACHE_OPTION=Always" \
            "WEBSITE_LOCAL_CACHE_SIZEINMB=1000" \
            "SCM_TOUCH_WEBCONFIG_AFTER_DEPLOYMENT=0" \
        --output none

    log_success "App Service optimization completed"

    # Database optimizations
    log_info "Optimizing Database configuration..."

    # Configure database parameters for performance
    case $ENVIRONMENT in
        "prod")
            # Production optimizations
            az postgres server configuration set \
                --server-name "$DATABASE_SERVER" \
                --resource-group "$RESOURCE_GROUP" \
                --name "shared_preload_libraries" \
                --value "pg_stat_statements" || true

            az postgres server configuration set \
                --server-name "$DATABASE_SERVER" \
                --resource-group "$RESOURCE_GROUP" \
                --name "work_mem" \
                --value "16384" || true  # 16MB

            az postgres server configuration set \
                --server-name "$DATABASE_SERVER" \
                --resource-group "$RESOURCE_GROUP" \
                --name "maintenance_work_mem" \
                --value "524288" || true  # 512MB
            ;;
        "staging")
            # Staging optimizations
            az postgres server configuration set \
                --server-name "$DATABASE_SERVER" \
                --resource-group "$RESOURCE_GROUP" \
                --name "work_mem" \
                --value "8192" || true  # 8MB
            ;;
    esac

    log_success "Database optimization completed"

    # Enable auto-scaling if not in dev environment
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        log_info "Configuring auto-scaling..."

        local app_service_plan
        app_service_plan=$(az webapp show \
            --name "$APP_SERVICE" \
            --resource-group "$RESOURCE_GROUP" \
            --query "serverFarmId" -o tsv | sed 's/.*\///')

        # Create auto-scale settings
        az monitor autoscale create \
            --resource-group "$RESOURCE_GROUP" \
            --resource "$app_service_plan" \
            --resource-type "Microsoft.Web/serverfarms" \
            --name "vigor-${ENVIRONMENT}-autoscale" \
            --min-count 2 \
            --max-count $(if [[ "$ENVIRONMENT" == "prod" ]]; then echo "10"; else echo "5"; fi) \
            --count 2 \
            --output none || true

        # Add scale-out rule (CPU > 70%)
        az monitor autoscale rule create \
            --resource-group "$RESOURCE_GROUP" \
            --autoscale-name "vigor-${ENVIRONMENT}-autoscale" \
            --condition "Percentage CPU > 70 avg 10m" \
            --scale out 1 \
            --output none || true

        # Add scale-in rule (CPU < 30%)
        az monitor autoscale rule create \
            --resource-group "$RESOURCE_GROUP" \
            --autoscale-name "vigor-${ENVIRONMENT}-autoscale" \
            --condition "Percentage CPU < 30 avg 10m" \
            --scale in 1 \
            --output none || true

        log_success "Auto-scaling configured"
    fi

    log_success "Performance optimization completed"
}

# Function to scale up resources
scale_up() {
    log_info "Scaling up resources..."

    # Get current App Service Plan SKU
    local current_sku
    current_sku=$(az appservice plan show \
        --name "vigor-${ENVIRONMENT}-asp" \
        --resource-group "$RESOURCE_GROUP" \
        --query "sku.name" -o tsv)

    log_info "Current App Service SKU: $current_sku"

    # Determine next tier
    local new_sku
    case $current_sku in
        "B1")
            new_sku="S1"
            ;;
        "S1")
            new_sku="P1V2"
            ;;
        "P1V2")
            new_sku="P2V2"
            ;;
        "P2V2")
            new_sku="P3V2"
            ;;
        *)
            log_warning "Already at highest tier or unknown SKU: $current_sku"
            return 0
            ;;
    esac

    log_info "Scaling App Service Plan to: $new_sku"
    az appservice plan update \
        --name "vigor-${ENVIRONMENT}-asp" \
        --resource-group "$RESOURCE_GROUP" \
        --sku "$new_sku" \
        --output none

    log_success "App Service scaled up to $new_sku"

    # Scale database if needed
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        local current_db_tier
        current_db_tier=$(az postgres server show \
            --name "$DATABASE_SERVER" \
            --resource-group "$RESOURCE_GROUP" \
            --query "sku.tier" -o tsv)

        if [[ "$current_db_tier" == "Basic" ]]; then
            log_info "Scaling database to GeneralPurpose tier..."
            az postgres server update \
                --name "$DATABASE_SERVER" \
                --resource-group "$RESOURCE_GROUP" \
                --sku-name "GP_Gen5_2" \
                --output none

            log_success "Database scaled to GeneralPurpose"
        fi
    fi

    log_success "Scale up completed"
}

# Function to scale down resources
scale_down() {
    log_info "Scaling down resources to save costs..."

    # Only allow scale down in dev environment or with explicit confirmation
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        log_warning "Scaling down in $ENVIRONMENT environment"
        read -p "Are you sure you want to scale down production resources? (yes/no): " confirm

        if [[ "$confirm" != "yes" ]]; then
            log_info "Scale down cancelled by user"
            return 0
        fi
    fi

    # Get current App Service Plan SKU
    local current_sku
    current_sku=$(az appservice plan show \
        --name "vigor-${ENVIRONMENT}-asp" \
        --resource-group "$RESOURCE_GROUP" \
        --query "sku.name" -o tsv)

    log_info "Current App Service SKU: $current_sku"

    # Determine lower tier
    local new_sku
    case $current_sku in
        "P3V2")
            new_sku="P2V2"
            ;;
        "P2V2")
            new_sku="P1V2"
            ;;
        "P1V2")
            new_sku="S1"
            ;;
        "S1")
            new_sku="B1"
            ;;
        *)
            log_warning "Already at lowest tier or unknown SKU: $current_sku"
            return 0
            ;;
    esac

    log_info "Scaling App Service Plan to: $new_sku"
    az appservice plan update \
        --name "vigor-${ENVIRONMENT}-asp" \
        --resource-group "$RESOURCE_GROUP" \
        --sku "$new_sku" \
        --output none

    log_success "App Service scaled down to $new_sku"

    log_success "Scale down completed"
}

# Main execution
case $OPERATION in
    "analyze")
        analyze_performance
        ;;
    "optimize")
        optimize_performance
        ;;
    "scale-up")
        scale_up
        ;;
    "scale-down")
        scale_down
        ;;
esac

log_success "Performance operation '$OPERATION' completed successfully!"

# Display final summary
log_info "Operation summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  App Service: $APP_SERVICE"
echo "  Database Server: $DATABASE_SERVER"
echo "  Operation: $OPERATION"
