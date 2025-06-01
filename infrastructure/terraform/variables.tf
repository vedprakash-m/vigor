# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

# Database Configuration
variable "postgres_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "vigoradmin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "Administrator password for PostgreSQL server"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.postgres_admin_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

# Security Configuration
variable "secret_key" {
  description = "Secret key for JWT tokens and application security"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.secret_key) >= 32
    error_message = "Secret key must be at least 32 characters long."
  }
}

# AI Provider API Keys
variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "perplexity_api_key" {
  description = "Perplexity AI API key"
  type        = string
  default     = ""
  sensitive   = true
}

# Admin Configuration
variable "admin_email" {
  description = "Administrator email address"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "Admin email must be a valid email address."
  }
}

# Scaling Configuration
variable "app_service_sku" {
  description = "App Service SKU for production scaling"
  type        = string
  default     = ""

  validation {
    condition = var.app_service_sku == "" || contains([
      "B1", "B2", "B3",       # Basic
      "S1", "S2", "S3",       # Standard  
      "P1v2", "P2v2", "P3v2", # Premium v2
      "P1v3", "P2v3", "P3v3"  # Premium v3
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid Azure App Service plan SKU."
  }
}

variable "redis_capacity" {
  description = "Redis cache capacity"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 2, 3, 4, 5, 6], var.redis_capacity)
    error_message = "Redis capacity must be between 0 and 6."
  }
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 5120

  validation {
    condition     = var.postgres_storage_mb >= 5120 && var.postgres_storage_mb <= 16777216
    error_message = "PostgreSQL storage must be between 5120 MB and 16777216 MB."
  }
}

# Feature Flags
variable "enable_high_availability" {
  description = "Enable high availability for production resources"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable advanced monitoring and alerting"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for App Service"
  type        = bool
  default     = false
}

# Cost Management
variable "budget_amount" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage (0-100)"
  type        = number
  default     = 80

  validation {
    condition     = var.budget_alert_threshold > 0 && var.budget_alert_threshold <= 100
    error_message = "Budget alert threshold must be between 1 and 100."
  }
}

# Networking
variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses for database access"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoints for secure communication"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Disaster Recovery
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

variable "enable_geo_redundancy" {
  description = "Enable geo-redundant storage for backups"
  type        = bool
  default     = false
} 