using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'West US 2' // Different region to avoid quota
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'
param postgresStorageMb = 10240 // 10GB for production

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// Cost-optimized configuration to avoid quota issues
param appServiceSku = 'B1' // Basic tier instead of Standard
param redisCapacity = 0 // Start with minimum

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
