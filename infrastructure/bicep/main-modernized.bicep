// Vigor Modernized Infrastructure - Single Resource Group Architecture
// Azure Functions + Cosmos DB + Flex Consumption Plan
@description('Environment name (prod)')
param environment string = 'prod'

@description('Azure region for resources')
param location string = 'West US 2'

@description('Application name')
param appName string = 'vigor'

@description('Secret key for JWT tokens')
@secure()
param secretKey string

@description('Existing Azure OpenAI endpoint (uses existing resource in rg-vemishra-rag)')
param azureOpenAiEndpoint string = 'https://aoai-vemishra-rag.openai.azure.com/'

@description('Azure OpenAI deployment name')
param azureOpenAiDeployment string = 'gpt-4o-mini'

@description('Azure OpenAI API key')
@secure()
param azureOpenAiApiKey string

// Variables
var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'bicep'
  Project: 'vigor-fitness-modernized'
  CostCenter: 'engineering'
  Architecture: 'serverless'
}

// Unified resource names (single resource group)
var functionAppName = 'vigor-functions'
var staticWebAppName = 'vigor-frontend'
var cosmosDbAccountName = 'vigor-cosmos-${environment}'
var storageAccountName = 'vigorsa${uniqueString(resourceGroup().id)}'
var keyVaultName = 'vigor-kv-${uniqueString(resourceGroup().id)}'
var appInsightsName = 'vigor-insights'
var logAnalyticsName = 'vigor-logs'
// Note: Using existing Azure OpenAI resource (aoai-vemishra-rag in rg-vemishra-rag)

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'production' ? 90 : 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Storage Account for Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
}

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  tags: commonTags
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// Cosmos DB Database
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosDbAccount
  name: 'vigor_db'
  properties: {
    resource: {
      id: 'vigor_db'
    }
  }
}

// Cosmos DB Containers
resource usersContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'users'
  properties: {
    resource: {
      id: 'users'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
    }
  }
}

resource workoutsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'workouts'
  properties: {
    resource: {
      id: 'workouts'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
    }
  }
}

resource workoutLogsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'workout_logs'
  properties: {
    resource: {
      id: 'workout_logs'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
    }
  }
}

resource aiMessagesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'ai_coach_messages'
  properties: {
    resource: {
      id: 'ai_coach_messages'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
      defaultTtl: 2592000 // 30 days TTL for chat messages
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
  }
}

// Note: Azure OpenAI uses existing resource (aoai-vemishra-rag in rg-vemishra-rag)
// with gpt-4o-mini deployment. Endpoint and API key are passed as parameters.

// Function App with Flex Consumption Plan
module functionApp './function-app-modernized.bicep' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    tags: commonTags
    appInsightsConnectionString: appInsights.properties.ConnectionString
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    storageAccountName: storageAccount.name
    storageAccountKey: storageAccount.listKeys().keys[0].value
    cosmosDbEndpoint: cosmosDbAccount.properties.documentEndpoint
    cosmosDbKey: cosmosDbAccount.listKeys().primaryMasterKey
    azureOpenAiEndpoint: azureOpenAiEndpoint
    azureOpenAiApiKey: azureOpenAiApiKey
    azureOpenAiDeployment: azureOpenAiDeployment
    secretKey: secretKey
  }
}

// Static Web App (Frontend)
module staticWebApp './static-web-app-modernized.bicep' = {
  name: 'staticWebApp'
  params: {
    name: staticWebAppName
    location: location // Use same region as other resources (West US 2)
    tags: commonTags
    functionAppUrl: 'https://${functionAppName}.azurewebsites.net'
  }
}

// Key Vault Secrets
resource secretKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'secret-key'
  properties: {
    value: secretKey
  }
}

resource azureOpenAiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'azure-openai-api-key'
  properties: {
    value: azureOpenAiApiKey
  }
}

resource cosmosConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'cosmos-connection-string'
  properties: {
    value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

// Grant Function App access to Key Vault
resource functionAppKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionAppName, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    ) // Key Vault Secrets User
    principalId: functionApp.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Grant Function App access to Cosmos DB
resource functionAppCosmosAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, functionAppName, 'Cosmos DB Data Contributor')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c'
    ) // Cosmos DB Data Contributor
    principalId: functionApp.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output functionAppName string = functionApp.outputs.functionAppName
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppUrl string = staticWebApp.outputs.staticWebAppUrl
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
output keyVaultName string = keyVault.name
output resourceGroupName string = resourceGroup().name
