#!/bin/bash

# Vigor Platform - Backup and Disaster Recovery Script
# Automated backup for databases, storage, and configurations

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
ENVIRONMENT="dev"
RESOURCE_GROUP=""
STORAGE_ACCOUNT=""
DATABASE_SERVER=""
BACKUP_TYPE="full"  # full, incremental, config-only
RETENTION_DAYS="30"

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
Vigor Platform - Backup and Disaster Recovery Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV     Environment (dev/staging/prod) [default: dev]
    -g, --resource-group RG   Resource group name
    -s, --storage-account SA  Storage account name
    -d, --database-server DB  Database server name
    -t, --type TYPE          Backup type (full/incremental/config-only) [default: full]
    -r, --retention DAYS     Retention period in days [default: 30]
    --restore               Restore mode instead of backup
    --restore-date DATE     Date for point-in-time restore (YYYY-MM-DD)
    -h, --help              Show this help message

Examples:
    $0 --environment prod --resource-group vigor-prod-rg --type full
    $0 -e staging -t incremental --retention 14
    $0 --restore --restore-date 2024-01-15 --environment prod

EOF
}

# Parse command line arguments
RESTORE_MODE="false"
RESTORE_DATE=""

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
        -s|--storage-account)
            STORAGE_ACCOUNT="$2"
            shift 2
            ;;
        -d|--database-server)
            DATABASE_SERVER="$2"
            shift 2
            ;;
        -t|--type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --restore)
            RESTORE_MODE="true"
            shift
            ;;
        --restore-date)
            RESTORE_DATE="$2"
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

if [[ -z "$STORAGE_ACCOUNT" ]]; then
    STORAGE_ACCOUNT="vigor${ENVIRONMENT}storage"
fi

if [[ -z "$DATABASE_SERVER" ]]; then
    DATABASE_SERVER="vigor-${ENVIRONMENT}-postgres"
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod"
    exit 1
fi

# Validate backup type
if [[ ! "$BACKUP_TYPE" =~ ^(full|incremental|config-only)$ ]]; then
    log_error "Backup type must be one of: full, incremental, config-only"
    exit 1
fi

log_info "Starting backup/restore operations for environment: $ENVIRONMENT"

# Check Azure CLI login
log_info "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    log_error "Azure CLI not authenticated. Please run 'az login'"
    exit 1
fi

log_success "Azure CLI authenticated"

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_CONTAINER="backups-${ENVIRONMENT}"

# Function to create backup container
create_backup_container() {
    log_info "Creating backup container if it doesn't exist..."
    az storage container create \
        --name "$BACKUP_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --output none 2>/dev/null || true

    log_success "Backup container ready: $BACKUP_CONTAINER"
}

# Function to backup database
backup_database() {
    log_info "Starting database backup..."

    local backup_name="db-backup-${ENVIRONMENT}-${TIMESTAMP}.sql"
    local temp_file="/tmp/${backup_name}"

    # Get database connection details from Key Vault
    local key_vault="vigor-${ENVIRONMENT}-kv"
    local db_password

    log_info "Retrieving database credentials from Key Vault..."
    db_password=$(az keyvault secret show \
        --vault-name "$key_vault" \
        --name "database-admin-password" \
        --query "value" -o tsv)

    if [[ -z "$db_password" ]]; then
        log_error "Failed to retrieve database password from Key Vault"
        return 1
    fi

    # Perform database dump
    log_info "Creating database dump..."
    PGPASSWORD="$db_password" pg_dump \
        --host="${DATABASE_SERVER}.postgres.database.azure.com" \
        --username="vigoradmin@${DATABASE_SERVER}" \
        --dbname="vigor" \
        --verbose \
        --clean \
        --no-owner \
        --no-privileges \
        --file="$temp_file"

    # Compress the backup
    log_info "Compressing backup file..."
    gzip "$temp_file"
    temp_file="${temp_file}.gz"

    # Upload to Azure Storage
    log_info "Uploading backup to Azure Storage..."
    az storage blob upload \
        --file "$temp_file" \
        --name "database/${backup_name}.gz" \
        --container-name "$BACKUP_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --overwrite

    # Clean up local file
    rm -f "$temp_file"

    log_success "Database backup completed: database/${backup_name}.gz"
}

# Function to backup storage account
backup_storage() {
    log_info "Starting storage account backup..."

    local backup_name="storage-backup-${ENVIRONMENT}-${TIMESTAMP}"

    # List all containers
    local containers
    containers=$(az storage container list \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --query "[].name" -o tsv)

    for container in $containers; do
        if [[ "$container" != "$BACKUP_CONTAINER" ]]; then
            log_info "Backing up container: $container"

            # Copy container contents to backup location
            az storage blob copy start-batch \
                --destination-container "$BACKUP_CONTAINER" \
                --destination-path "storage-backup/${backup_name}/${container}" \
                --source-container "$container" \
                --account-name "$STORAGE_ACCOUNT" \
                --auth-mode login
        fi
    done

    log_success "Storage backup initiated: storage-backup/${backup_name}"
}

# Function to backup configurations
backup_configurations() {
    log_info "Starting configuration backup..."

    local backup_name="config-backup-${ENVIRONMENT}-${TIMESTAMP}"
    local temp_dir="/tmp/${backup_name}"

    mkdir -p "$temp_dir"

    # Backup Key Vault secrets (metadata only, not values)
    log_info "Backing up Key Vault configuration..."
    local key_vault="vigor-${ENVIRONMENT}-kv"

    az keyvault secret list \
        --vault-name "$key_vault" \
        --query "[].{name:name, contentType:contentType, attributes:attributes}" \
        > "$temp_dir/keyvault-secrets.json"

    # Backup App Service configuration
    log_info "Backing up App Service configuration..."
    local app_service="vigor-${ENVIRONMENT}-app"

    az webapp config show \
        --name "$app_service" \
        --resource-group "$RESOURCE_GROUP" \
        > "$temp_dir/app-service-config.json"

    az webapp config appsettings list \
        --name "$app_service" \
        --resource-group "$RESOURCE_GROUP" \
        > "$temp_dir/app-service-settings.json"

    # Backup database configuration
    log_info "Backing up database configuration..."
    az postgres server show \
        --name "$DATABASE_SERVER" \
        --resource-group "$RESOURCE_GROUP" \
        > "$temp_dir/database-config.json"

    # Create archive
    tar -czf "${temp_dir}.tar.gz" -C "/tmp" "$backup_name"

    # Upload to Azure Storage
    az storage blob upload \
        --file "${temp_dir}.tar.gz" \
        --name "configurations/${backup_name}.tar.gz" \
        --container-name "$BACKUP_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --overwrite

    # Clean up
    rm -rf "$temp_dir" "${temp_dir}.tar.gz"

    log_success "Configuration backup completed: configurations/${backup_name}.tar.gz"
}

# Function to restore database
restore_database() {
    local restore_file="$1"

    log_warning "Starting database restore. This will overwrite existing data!"
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled by user"
        return 0
    fi

    log_info "Downloading backup file..."
    local temp_file="/tmp/restore-${TIMESTAMP}.sql.gz"

    az storage blob download \
        --name "$restore_file" \
        --container-name "$BACKUP_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --file "$temp_file"

    # Decompress
    gunzip "$temp_file"
    temp_file="/tmp/restore-${TIMESTAMP}.sql"

    # Get database credentials
    local key_vault="vigor-${ENVIRONMENT}-kv"
    local db_password

    db_password=$(az keyvault secret show \
        --vault-name "$key_vault" \
        --name "database-admin-password" \
        --query "value" -o tsv)

    # Restore database
    log_info "Restoring database..."
    PGPASSWORD="$db_password" psql \
        --host="${DATABASE_SERVER}.postgres.database.azure.com" \
        --username="vigoradmin@${DATABASE_SERVER}" \
        --dbname="vigor" \
        --file="$temp_file"

    rm -f "$temp_file"

    log_success "Database restore completed"
}

# Function to clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than $RETENTION_DAYS days..."

    local cutoff_date
    cutoff_date=$(date -d "$RETENTION_DAYS days ago" +"%Y-%m-%d")

    # List and delete old backups
    az storage blob list \
        --container-name "$BACKUP_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --query "[?properties.lastModified < '${cutoff_date}'].name" -o tsv | \
    while read -r blob_name; do
        if [[ -n "$blob_name" ]]; then
            log_info "Deleting old backup: $blob_name"
            az storage blob delete \
                --name "$blob_name" \
                --container-name "$BACKUP_CONTAINER" \
                --account-name "$STORAGE_ACCOUNT" \
                --auth-mode login
        fi
    done

    log_success "Old backup cleanup completed"
}

# Main execution
if [[ "$RESTORE_MODE" == "true" ]]; then
    log_info "Running in restore mode"

    if [[ -n "$RESTORE_DATE" ]]; then
        # Find backup from specific date
        backup_file=$(az storage blob list \
            --container-name "$BACKUP_CONTAINER" \
            --account-name "$STORAGE_ACCOUNT" \
            --auth-mode login \
            --query "[?contains(name, '${RESTORE_DATE}') && contains(name, 'database/')].name" -o tsv | head -n1)

        if [[ -n "$backup_file" ]]; then
            restore_database "$backup_file"
        else
            log_error "No database backup found for date: $RESTORE_DATE"
            exit 1
        fi
    else
        log_error "Restore date is required for restore mode. Use --restore-date YYYY-MM-DD"
        exit 1
    fi
else
    log_info "Running in backup mode: $BACKUP_TYPE"

    create_backup_container

    case $BACKUP_TYPE in
        "full")
            backup_database
            backup_storage
            backup_configurations
            ;;
        "incremental")
            backup_database
            backup_configurations
            ;;
        "config-only")
            backup_configurations
            ;;
    esac

    cleanup_old_backups
fi

log_success "Backup/restore operations completed successfully!"

# Display summary
log_info "Operation summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Database Server: $DATABASE_SERVER"
echo "  Operation: $(if [[ "$RESTORE_MODE" == "true" ]]; then echo "Restore"; else echo "Backup ($BACKUP_TYPE)"; fi)"
echo "  Timestamp: $TIMESTAMP"
