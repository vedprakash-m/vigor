terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Use local backend for CI/CD validation
  # For production deployments, configure azurerm backend via CLI or environment variables
  backend "local" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# Data sources
data "azurerm_client_config" "current" {}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local values
locals {
  environment = var.environment
  app_name    = "vigor"
  location    = var.location

  # Generate unique names
  unique_suffix = random_string.suffix.result

  # Resource naming convention
  resource_group_name     = "${local.app_name}-${local.environment}-rg"
  app_service_plan_name   = "${local.app_name}-${local.environment}-asp"
  app_service_name        = "${local.app_name}-${local.environment}-app-${local.unique_suffix}"
  postgres_server_name    = "${local.app_name}-${local.environment}-db-${local.unique_suffix}"
  redis_name              = "${local.app_name}-${local.environment}-redis-${local.unique_suffix}"
  storage_account_name    = "${local.app_name}${local.environment}sa${local.unique_suffix}"
  key_vault_name          = "${local.app_name}-${local.environment}-kv-${local.unique_suffix}"
  app_insights_name       = "${local.app_name}-${local.environment}-ai"
  log_analytics_name      = "${local.app_name}-${local.environment}-la"
  container_registry_name = "${local.app_name}${local.environment}acr${local.unique_suffix}"

  # Common tags
  common_tags = {
    Environment = local.environment
    Application = local.app_name
    ManagedBy   = "terraform"
    Project     = "vigor-fitness"
    CostCenter  = "engineering"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# Log Analytics Workspace (required for Application Insights)
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "production" ? 90 : 30
  tags                = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "ZRS" : "LRS"

  # Security configurations
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  default_to_oauth_authentication = true

  # Enable HTTPS traffic only
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  blob_properties {
    # Restrict public access
    public_access_enabled = false

    cors_rule {
      allowed_headers = ["Content-Type", "x-ms-blob-type", "x-ms-blob-content-type"]
      allowed_methods = ["GET", "HEAD", "POST", "PUT"]
      allowed_origins = [
        "https://${local.app_service_name}-frontend.azurestaticapps.net",
        var.environment != "production" ? "http://localhost:5173" : ""
      ]
      exposed_headers    = [""]
      max_age_in_seconds = 3600
    }

    # Enable versioning and soft delete for production
    versioning_enabled = var.environment == "production"

    delete_retention_policy {
      days = var.environment == "production" ? 30 : 7
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = []
    ip_rules                   = []
  }

  tags = local.common_tags
}

# Container Registry (for Docker images)
resource "azurerm_container_registry" "main" {
  name                = local.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.environment == "production" ? "Premium" : "Basic"
  admin_enabled       = true

  # Security configurations
  public_network_access_enabled = var.environment == "production" ? false : true
  zone_redundancy_enabled       = var.environment == "production"
  export_policy_enabled         = false
  quarantine_policy_enabled     = var.environment == "production"
  trust_policy_enabled          = var.environment == "production"
  retention_policy_enabled      = var.environment == "production"

  dynamic "network_rule_set" {
    for_each = var.environment == "production" ? [1] : []
    content {
      default_action  = "Deny"
      ip_rule         = []
      virtual_network = []
    }
  }

  tags = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 30
  purge_protection_enabled   = var.environment == "production"

  # Security configurations
  public_network_access_enabled   = false
  enable_rbac_authorization       = false
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
    ]
  }

  tags = local.common_tags
}

# PostgreSQL Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = local.postgres_server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "14"

  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password

  storage_mb = var.environment == "production" ? 32768 : 5120 # 32GB prod, 5GB dev
  sku_name   = var.environment == "production" ? "GP_Standard_D2s_v3" : "B_Standard_B1ms"

  backup_retention_days = var.environment == "production" ? 35 : 7

  # Security configurations
  geo_redundant_backup_enabled  = var.environment == "production"
  public_network_access_enabled = false

  # Encryption
  customer_managed_key {
    key_vault_key_id = null # Use service-managed keys for simplicity
  }

  high_availability {
    mode = var.environment == "production" ? "ZoneRedundant" : "Disabled"
  }

  tags = local.common_tags
}

# PostgreSQL Firewall Rule (allow Azure services)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "vigor_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = local.redis_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.environment == "production" ? 1 : 0 # 1GB prod, 250MB dev
  family              = var.environment == "production" ? "C" : "C"
  sku_name            = var.environment == "production" ? "Standard" : "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    enable_authentication = true
  }

  tags = local.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.environment == "production" ? "P1v3" : "B1"

  tags = local.common_tags
}

# App Service for Backend
resource "azurerm_linux_web_app" "backend" {
  name                = "${local.app_service_name}-backend"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = var.environment == "production"

    application_stack {
      python_version = "3.11"
    }

    app_command_line = "gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000"
  }

  app_settings = {
    # App Configuration
    "ENVIRONMENT" = local.environment
    "DEBUG"       = var.environment != "production" ? "true" : "false"
    "SECRET_KEY"  = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=secret-key)"

    # Database
    "DATABASE_URL" = "postgresql://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"

    # Redis
    "REDIS_URL" = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"

    # AI Providers (from Key Vault)
    "OPENAI_API_KEY"     = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=openai-api-key)"
    "GEMINI_API_KEY"     = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=gemini-api-key)"
    "PERPLEXITY_API_KEY" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=perplexity-api-key)"
    "LLM_PROVIDER"       = "gemini"

    # Monitoring
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # CORS
    "CORS_ORIGINS" = jsonencode([
      "https://${azurerm_static_site.frontend.default_host_name}",
      var.environment != "production" ? "http://localhost:5173" : ""
    ])

    # Admin
    "ADMIN_EMAIL" = var.admin_email

    # Container Registry
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.main.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.main.admin_password
  }

  identity {
    type = "SystemAssigned"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  tags = local.common_tags
}

# Static Web App for Frontend
resource "azurerm_static_site" "frontend" {
  name                = "${local.app_service_name}-frontend"
  resource_group_name = azurerm_resource_group.main.name
  location            = "East US2" # Static Web Apps limited regions
  sku_tier            = var.environment == "production" ? "Standard" : "Free"
  sku_size            = var.environment == "production" ? "Standard" : "Free"

  tags = local.common_tags
}

# Key Vault Access Policy for App Service
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = azurerm_linux_web_app.backend.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "secrets" {
  for_each = {
    "secret-key"         = var.secret_key
    "openai-api-key"     = var.openai_api_key
    "gemini-api-key"     = var.gemini_api_key
    "perplexity-api-key" = var.perplexity_api_key
  }

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}
