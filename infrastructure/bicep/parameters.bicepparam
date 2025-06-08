using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'Central US' // Changed from West US 2 to avoid quota issues
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'
param postgresStorageMb = 10240 // 10GB for production

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// Scaling configuration (optimized for quota availability)
param appServiceSku = 'P1V2' // Premium V2 tier to avoid Basic/Standard quota limits
param redisCapacity = 1 // 1GB

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
