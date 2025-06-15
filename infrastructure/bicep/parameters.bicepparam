using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'Central US' // Single region for simplicity and cost
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// Cost-optimized configuration
param appServiceSku = 'F1' // FREE tier - $0/month for basic workloads

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
