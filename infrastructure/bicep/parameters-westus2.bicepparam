using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'West US 2' // Different region to avoid quota
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// Ultra cost-optimized configuration - NO Redis needed!
param appServiceSku = 'F1' // FREE tier - $0/month!

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
