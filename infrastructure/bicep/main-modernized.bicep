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

@description('Azure OpenAI endpoint (AI Foundry project)')
param azureOpenAiEndpoint string = 'https://vigor-openai.services.ai.azure.com/api/projects/vigor-foundry'

@description('Azure OpenAI deployment name')
param azureOpenAiDeployment string = 'gpt-5-mini'

// Note: AZURE_OPENAI_API_KEY is set manually in Azure Portal and not managed by Bicep
// This prevents accidental overwrites during deployments

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
var appInsightsName = 'vigor-insights'
var logAnalyticsName = 'vigor-logs'
// Note: Using Azure AI Foundry project (vigor-foundry) via vigor-openai.services.ai.azure.com

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
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

// Ghost Engine Cosmos DB Containers (Phase 7.0.5)
// These containers store Ghost intelligence data per Tech Spec §2.4

resource ghostActionsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'ghost_actions'
  properties: {
    resource: {
      id: 'ghost_actions'
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

resource trustStatesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'trust_states'
  properties: {
    resource: {
      id: 'trust_states'
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

resource trainingBlocksContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'training_blocks'
  properties: {
    resource: {
      id: 'training_blocks'
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

resource phenomeContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'phenome'
  properties: {
    resource: {
      id: 'phenome'
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

resource decisionReceiptsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'decision_receipts'
  properties: {
    resource: {
      id: 'decision_receipts'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
      defaultTtl: 7776000 // 90-day TTL per Tech Spec §2.4
    }
  }
}

resource pushQueueContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'push_queue'
  properties: {
    resource: {
      id: 'push_queue'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
      defaultTtl: 604800 // 7-day TTL for transient push queue items
    }
  }
}

// Note: Azure OpenAI uses Azure AI Foundry project (vigor-foundry via vigor-openai.services.ai.azure.com)
// with gpt-5-mini deployment. Endpoint and API key are passed as parameters.

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
    azureOpenAiDeployment: azureOpenAiDeployment
    secretKey: secretKey
    envName: environment
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

// Grant Function App access to Cosmos DB
resource functionAppCosmosAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, functionAppName, 'Cosmos DB Data Contributor')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '00000000-0000-0000-0000-000000000002'
    ) // Cosmos DB Built-in Data Contributor (NOT the generic 'Contributor' role)
    principalId: functionApp.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output functionAppName string = functionApp.outputs.functionAppName
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppUrl string = staticWebApp.outputs.staticWebAppUrl
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
output resourceGroupName string = resourceGroup().name
