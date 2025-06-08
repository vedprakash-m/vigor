using './main.bicep'

// Environment configuration
param environment = 'prod'
param location = 'Central US' // Switch to Central US for better quota availability
param appName = 'vigor'

// Database configuration
param postgresAdminUsername = 'vigoradmin'

// Admin configuration
param adminEmail = 'admin@vigor-fitness.com'

// QUOTA-AWARE configuration - try B1 Basic instead of F1 Free
param appServiceSku = 'B1' // Basic B1 - only $13/month, usually has quota

// Secrets will be provided via Azure CLI or GitHub Actions
param postgresAdminPassword = '' // Will be overridden
param secretKey = '' // Will be overridden
param openaiApiKey = '' // Will be overridden
param geminiApiKey = '' // Will be overridden
param perplexityApiKey = '' // Will be overridden
