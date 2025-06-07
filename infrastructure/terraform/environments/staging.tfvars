# Staging Environment Configuration
environment = "staging"
location    = "East US"

# Database Configuration
postgres_admin_username = "vigoradmin"
postgres_storage_mb     = 10240  # 10GB for staging

# Security (these will be overridden by secrets in CI/CD)
admin_email = "admin@vigor-fitness.com"

# Scaling Configuration (moderate for staging)
app_service_sku    = "S1"       # Standard tier
redis_capacity     = 1          # 1GB
budget_amount      = 200        # $200/month budget for staging

# Feature Flags
enable_high_availability = true
enable_autoscaling      = true
enable_monitoring       = true
enable_backup          = true

# Staging-specific settings
backup_retention_days = 7
log_retention_days    = 30
