// Cost-optimized single-slot deployment configuration
@description('Environment name (always prod for cost optimization)')
param environment string = 'prod'

@description('Azure region for resources')
param location string = 'Central US'

@description('Application name')
param appName string = 'vigor'

// Simplified parameters - only what we need
@description('PostgreSQL admin username')
param postgresAdminUsername string

@description('PostgreSQL admin password')
@secure()
param postgresAdminPassword string

@description('Secret key for JWT tokens')
@secure()
param secretKey string

@description('OpenAI API key')
@secure()
param openaiApiKey string = ''

// Cost-optimized SKUs
@description('App Service SKU - B1 for cost optimization')
param appServiceSku string = 'B1'

@description('PostgreSQL SKU - Basic for cost optimization')
param postgresqlSku string = 'B_Gen5_1'

// Single resource group for cost optimization
var resourceGroupName = 'vigor-rg'

// Static resource names (no staging variants)
var appServicePlanName = 'vigor-app-plan'
var backendWebAppName = 'vigor-backend'
var postgresServerName = 'vigor-db'
var storageAccountName = 'vigorsa99'
var keyVaultName = 'vigor-kv'

// Cost-optimized tags
var commonTags = {
  Environment: 'production'
  Application: appName
  CostOptimized: 'true'
  NoStaging: 'true'
}

// App Service Plan - Basic B1 only
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: commonTags
  sku: {
    name: appServiceSku
    tier: 'Basic'
    size: appServiceSku
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true // Linux
  }
}

// PostgreSQL Server - Basic tier only
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  tags: commonTags
  sku: {
    name: postgresqlSku
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    version: '15'
    storage: {
      storageSizeGB: 32 // Minimum for cost
    }
    backup: {
      backupRetentionDays: 7 // Minimum for cost
      geoRedundantBackup: 'Disabled' // Cost optimization
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Key Vault - Standard tier
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard' // Cost optimization
    }
    tenantId: tenant().tenantId
    enablePurgeProtection: false // Cost optimization - allows deletion
    softDeleteRetentionInDays: 30 // Minimum
    accessPolicies: []
  }
}

// Storage Account - Standard LRS for cost
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_LRS' // Cost optimization
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// SINGLE-SLOT App Service (no staging)
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: backendWebAppName
  location: location
  tags: commonTags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      alwaysOn: false // Cost optimization - allows sleeping
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: 'postgresql://${postgresAdminUsername}:${postgresAdminPassword}@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/postgres'
        }
        {
          name: 'SECRET_KEY'
          value: secretKey
        }
        {
          name: 'OPENAI_API_KEY'
          value: openaiApiKey
        }
        {
          name: 'ENVIRONMENT'
          value: 'production'
        }
        {
          name: 'DEBUG'
          value: 'false'
        }
        {
          name: 'LLM_PROVIDER'
          value: 'fallback'
        }
        {
          name: 'PORT'
          value: '8000'
        }
        {
          name: 'COST_OPTIMIZED'
          value: 'true'
        }
      ]
      healthCheckPath: '/health'
    }
  }
}

// Key Vault access for App Service
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}

// Outputs
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output postgresqlFQDN string = postgresqlServer.properties.fullyQualifiedDomainName
output keyVaultUri string = keyVault.properties.vaultUri
output resourceGroupName string = resourceGroupName
output totalMonthlyCost string = 'Estimated $43/month (B1 App Service + Basic PostgreSQL + Standard Key Vault + Standard Storage)'
