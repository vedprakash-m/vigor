# Development Environment Configuration
environment = "dev"
location    = "East US"

# Database Configuration
postgres_admin_username = "vigoradmin"
postgres_storage_mb     = 5120  # 5GB minimum

# Security (these will be overridden by secrets in CI/CD)
admin_email = "admin@vigor-fitness.com"

# Scaling Configuration (smaller for dev)
app_service_sku    = "B1"       # Basic tier
redis_capacity     = 0          # 250MB
budget_amount      = 50         # $50/month budget for dev

# Feature Flags
enable_high_availability = false
enable_autoscaling      = false
enable_monitoring       = true
enable_backup          = true
enable_private_endpoint = false
enable_geo_redundancy  = false

# Cost Management
budget_alert_threshold = 80

# Backup Configuration
backup_retention_days = 7

# Additional Tags
additional_tags = {
  Purpose     = "development"
  Owner       = "engineering-team"
  CostCenter  = "development"
  Environment = "dev"
} 