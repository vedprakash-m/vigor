// Modernized Function App with Flex Consumption Plan
param name string
param location string
param tags object
param appInsightsConnectionString string
param appInsightsInstrumentationKey string
param storageAccountName string
@secure()
param storageAccountKey string
param cosmosDbEndpoint string
@secure()
param cosmosDbKey string
@secure()
param geminiApiKey string
@secure()
param secretKey string

// Function App with Flex Consumption Plan
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        // Cosmos DB Configuration
        {
          name: 'COSMOS_DB_ENDPOINT'
          value: cosmosDbEndpoint
        }
        {
          name: 'COSMOS_DB_KEY'
          value: cosmosDbKey
        }
        {
          name: 'COSMOS_DB_DATABASE'
          value: 'vigor_db'
        }
        // AI Configuration (Single Provider)
        {
          name: 'AI_PROVIDER'
          value: 'gemini-flash-2.5'
        }
        {
          name: 'GOOGLE_AI_API_KEY'
          value: geminiApiKey
        }
        {
          name: 'AI_MONTHLY_BUDGET'
          value: '50'
        }
        {
          name: 'AI_COST_THRESHOLD'
          value: '40'
        }
        // Application Settings
        {
          name: 'JWT_SECRET_KEY'
          value: secretKey
        }
        {
          name: 'ENVIRONMENT'
          value: 'production'
        }
        {
          name: 'LOG_LEVEL'
          value: 'INFO'
        }
        // Azure Authentication
        {
          name: 'AZURE_TENANT_ID'
          value: 'VED'
        }
        {
          name: 'AZURE_DOMAIN_ID'
          value: 'vedid.onmicrosoft.com'
        }
        {
          name: 'AZURE_MAX_CONCURRENT_USERS'
          value: '100'
        }
      ]
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

// App Service Plan - Basic tier for reliable deployment
// Using B1 instead of Consumption due to quota limits
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${name}-plan'
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    reserved: true // Required for Linux
  }
  kind: 'linux'
}

// Outputs
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output functionAppPrincipalId string = functionApp.identity.principalId
