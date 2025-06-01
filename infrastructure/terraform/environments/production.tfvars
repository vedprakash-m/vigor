# Production Environment Configuration
environment = "production"
location    = "East US"

# Database Configuration
postgres_admin_username = "vigoradmin"
postgres_storage_mb     = 32768  # 32GB for production

# Security (these will be overridden by secrets in CI/CD)
admin_email = "admin@vigor-fitness.com"

# Scaling Configuration (production-ready)
app_service_sku    = "P1v3"      # Premium tier for production
redis_capacity     = 1          # 1GB
budget_amount      = 500        # $500/month budget for production

# Feature Flags
enable_high_availability = true
enable_autoscaling      = true
enable_monitoring       = true
enable_backup          = true
enable_private_endpoint = true
enable_geo_redundancy  = true

# Cost Management
budget_alert_threshold = 80

# Backup Configuration
backup_retention_days = 35       # Extended retention for production

# Network Security (production IPs - update with actual IPs)
allowed_ip_addresses = [
  # "203.0.113.0/24",  # Office network
  # "198.51.100.0/24"  # VPN network
]

# Additional Tags
additional_tags = {
  Purpose     = "production"
  Owner       = "platform-team"
  CostCenter  = "production"
  Environment = "production"
  Compliance  = "required"
  Backup      = "required"
} 