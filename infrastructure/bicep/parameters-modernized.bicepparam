using './main-modernized.bicep'

param environment = 'prod'
param location = 'West US 2'
param appName = 'vigor'
param secretKey = 'your-secret-key-here' // Replace with actual secret or use Key Vault reference
param openAiApiKey = 'your-openai-api-key-here' // Replace with actual API key or use Key Vault reference
