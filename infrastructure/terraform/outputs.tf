# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Application URLs
output "backend_url" {
  description = "URL of the backend App Service"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  description = "URL of the frontend Static Web App"
  value       = "https://${azurerm_static_site.frontend.default_host_name}"
}

# Database
output "postgres_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "database_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${var.postgres_admin_username}:***@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive   = true
}

# Redis Cache
output "redis_hostname" {
  description = "Redis cache hostname"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_ssl_port" {
  description = "Redis cache SSL port"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_connection_string" {
  description = "Redis connection string (without access key)"
  value       = "rediss://:***@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
  sensitive   = true
}

# Storage
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

# Container Registry
output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

# Key Vault
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# Monitoring
output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

# App Service
output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.backend.name
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "app_service_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = azurerm_linux_web_app.backend.identity[0].principal_id
}

# Static Web App
output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_site.frontend.name
}

output "static_web_app_api_key" {
  description = "API key for the Static Web App"
  value       = azurerm_static_site.frontend.api_key
  sensitive   = true
}

# Environment Information
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "unique_suffix" {
  description = "Unique suffix used for resource names"
  value       = random_string.suffix.result
}

# Deployment Information
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment        = var.environment
    location           = var.location
    resource_group     = azurerm_resource_group.main.name
    backend_url        = "https://${azurerm_linux_web_app.backend.default_hostname}"
    frontend_url       = "https://${azurerm_static_site.frontend.default_host_name}"
    postgres_server    = azurerm_postgresql_flexible_server.main.fqdn
    redis_hostname     = azurerm_redis_cache.main.hostname
    key_vault          = azurerm_key_vault.main.name
    container_registry = azurerm_container_registry.main.login_server
  }
}

# Cost Estimation (approximate monthly costs in USD)
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown in USD"
  value = {
    total_estimated = var.environment == "production" ? "$180-220" : "$45-65"
    breakdown = {
      app_service_plan     = var.environment == "production" ? "$73" : "$13"
      postgresql           = var.environment == "production" ? "$45-65" : "$15-25"
      redis_cache          = var.environment == "production" ? "$25" : "$8"
      static_web_app       = var.environment == "production" ? "$10" : "$0"
      storage_account      = "$2-5"
      key_vault            = "$1-3"
      application_insights = "$5-10"
      container_registry   = var.environment == "production" ? "$5" : "$5"
      bandwidth            = "$5-15"
    }
    notes = [
      "Costs vary based on usage and region",
      "Production includes high availability and premium features",
      "AI API costs are additional and depend on usage",
      "Use Azure Cost Management for accurate tracking"
    ]
  }
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Next steps for deployment"
  value = {
    steps = [
      "1. Configure GitHub Actions with these outputs",
      "2. Set up CI/CD pipeline using the deployment script",
      "3. Configure domain name and SSL certificates",
      "4. Set up monitoring and alerting",
      "5. Configure backup and disaster recovery",
      "6. Test the application thoroughly"
    ]
    github_secrets_needed = [
      "AZURE_CREDENTIALS",
      "CONTAINER_REGISTRY_USERNAME",
      "CONTAINER_REGISTRY_PASSWORD",
      "DATABASE_URL",
      "REDIS_URL",
      "APPLICATIONINSIGHTS_CONNECTION_STRING"
    ]
  }
} 