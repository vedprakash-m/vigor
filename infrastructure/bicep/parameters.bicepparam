using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'West US 2' // Optimized: West Coast location for best user latency
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'
param postgresStorageMb = 10240 // 10GB for production

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// Scaling configuration (optimized for quota availability)
param appServiceSku = 'S1' // Standard tier to avoid Basic quota limits
param redisCapacity = 1 // 1GB

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
