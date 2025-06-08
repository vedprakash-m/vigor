# Production Environment Configuration
environment = "prod"
location    = "East US"

# Database Configuration
postgres_admin_username = "vigoradmin"
postgres_storage_mb     = 10240 # 10GB for production

# Security (these will be overridden by secrets in CI/CD)
admin_email = "admin@vigor-fitness.com"

# Scaling Configuration (production-ready but cost-optimized)
app_service_sku = "S1" # Standard tier
redis_capacity  = 1    # 1GB
budget_amount   = 150  # $150/month budget for production

# Feature Flags
enable_high_availability = true
enable_autoscaling       = true
enable_monitoring        = true
enable_backup            = true
enable_private_endpoint  = false
enable_geo_redundancy    = false

# Cost Management
budget_alert_threshold = 80

# Backup Configuration
backup_retention_days = 14

# Additional Tags
additional_tags = {
  Purpose     = "production"
  Owner       = "engineering-team"
  CostCenter  = "production"
  Environment = "prod"
}
