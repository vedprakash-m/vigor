// Bicep equivalent of your main.tf - for comparison
@description('Environment name (prod)')
param environment string = 'prod'

@description('Azure region for resources')
param location string = 'East US'

@description('Application name')
param appName string = 'vigor'

@description('PostgreSQL admin username')
param postgresAdminUsername string

@description('PostgreSQL admin password')
@secure()
param postgresAdminPassword string

@description('Secret key for JWT tokens')
@secure()
param secretKey string

@description('Admin email address')
param adminEmail string

@description('OpenAI API key')
@secure()
param openaiApiKey string = ''

@description('Gemini API key')
@secure()
param geminiApiKey string = ''

@description('Perplexity API key')
@secure()
param perplexityApiKey string = ''

@description('App Service SKU')
param appServiceSku string = 'S1'

@description('Resource group name where database resources (PostgreSQL) will live. Allows you to delete the app RG without losing data.')
param databaseResourceGroup string = 'vigor-db-rg'

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'bicep'
  Project: 'vigor-fitness'
  CostCenter: 'engineering'
}

// Resource names
var appServicePlanName = '${appName}-${environment}-asp'
var appServiceName = '${appName}-${environment}-app-${uniqueSuffix}'
var postgresServerName = '${appName}-${environment}-db-${uniqueSuffix}'
var storageAccountName = '${appName}${environment}sa${uniqueSuffix}'
var keyVaultName = toLower('${appName}${substring(uniqueSuffix,0,12)}kv')
var appInsightsName = '${appName}-${environment}-ai'
var logAnalyticsName = '${appName}-${environment}-la'
var containerRegistryName = '${appName}acr${uniqueSuffix}'

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

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: environment == 'production' ? 'Standard_ZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// Container Registry - Use Basic (usually has quota) or fallback to shared registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard' // Standard is widely supported across regions
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
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
    tenantId: tenant().tenantId
    softDeleteRetentionInDays: 30
    enablePurgeProtection: environment == 'production' || environment == 'prod'
    publicNetworkAccess: 'Disabled'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    accessPolicies: []
  }
}

// ---------------------------------------------------------------------------
// Database module deployed to separate resource group
// ---------------------------------------------------------------------------

var databaseName = 'vigor_db'

module db './db.bicep' = {
  name: 'dbModule'
  scope: resourceGroup(databaseResourceGroup)
  params: {
    location: location
    environment: environment
    postgresServerName: postgresServerName
    postgresAdminUsername: postgresAdminUsername
    postgresAdminPassword: postgresAdminPassword
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: commonTags
  sku: {
    name: appServiceSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service (Backend)
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${appServiceName}-backend'
  location: location
  tags: commonTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: environment == 'production'
      linuxFxVersion: 'PYTHON|3.11'
      appCommandLine: 'gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000'
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'DEBUG'
          value: environment != 'production' ? 'true' : 'false'
        }
        {
          name: 'SECRET_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=secret-key)'
        }
        {
          name: 'DATABASE_URL'
          value: 'postgresql://${postgresAdminUsername}:${postgresAdminPassword}@${db.outputs.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
        }
        {
          name: 'OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=openai-api-key)'
        }
        {
          name: 'GEMINI_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=gemini-api-key)'
        }
        {
          name: 'PERPLEXITY_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=perplexity-api-key)'
        }
        {
          name: 'LLM_PROVIDER'
          value: 'gemini'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ADMIN_EMAIL'
          value: adminEmail
        }
      ]
    }
  }
}

// Static Web App (Frontend)
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: '${appServiceName}-frontend'
  location: 'Central US' // Use same region as other resources for consistency
  tags: commonTags
  sku: {
    name: 'Free' // Always use Free tier for cost optimization
  }
  properties: {}
}

// Key Vault Access Policy for App Service
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: ['Get', 'List']
        }
      }
    ]
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

resource openaiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openaiApiKey
  }
}

resource geminiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'gemini-api-key'
  properties: {
    value: geminiApiKey
  }
}

resource perplexityApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'perplexity-api-key'
  properties: {
    value: perplexityApiKey
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output backendUrl string = 'https://${appService.properties.defaultHostName}'
output frontendUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output postgresServerFqdn string = db.outputs.fullyQualifiedDomainName
output keyVaultName string = keyVault.name
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output applicationInsightsConnectionString string = appInsights.properties.ConnectionString
