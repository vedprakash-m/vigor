using './main-modernized.bicep'

param environment = 'prod'
param location = 'West US 2'
param appName = 'vigor'
// Generate a secure random key for JWT signing
param secretKey = 'vigor-jwt-secret-key-prod-2026'
// Use existing Azure OpenAI resource in rg-vemishra-rag (East US 2)
param azureOpenAiEndpoint = 'https://aoai-vemishra-rag.openai.azure.com/'
param azureOpenAiDeployment = 'gpt-4o-mini'
param azureOpenAiApiKey = '0e32e9e7fe52482cbd87743a818946b3'
