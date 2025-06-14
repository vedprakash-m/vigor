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

// Note: Container Registry related parameters are being phased out as we move to App Service + Functions
@description('Deploy Azure Container Registry (set to true only if you need a new ACR).')
param deployContainerRegistry bool = false

@description('Use direct App Service deployment instead of containers (true for new architecture, false for legacy)')
param useDirectDeployment bool = true

// Variables
// Using these variables in resource names to ensure uniqueness
var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'bicep'
  Project: 'vigor-fitness'
  CostCenter: 'engineering'
}

// ---------------------------------------------------------------------------
// Static resource names as per naming standard (no random suffixes)
// ---------------------------------------------------------------------------
var appServicePlanName = 'vigor-app-plan'
var backendWebAppName = 'vigor-backend'
var frontendAppName = 'vigor-frontend'
var functionAppName = 'vigor-ai-functions'
var staticWebAppName = 'vigor-static-webapp'
var postgresServerName = 'vigor-db-server'
var storageAccountName = 'vigorsa99'
var keyVaultName = 'vigor-kv'
var appInsightsName = 'vigor-ai'
var logAnalyticsName = 'vigor-la'
// Marked as deprecated as we're moving away from containers
var containerRegistryName = 'vigoracr'

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

// Storage Account in persistent (database) resource group
module storageMod './storage.bicep' = {
  name: 'storageModule'
  scope: resourceGroup(databaseResourceGroup)
  params: {
    name: storageAccountName
    location: location
    tags: commonTags
  }
}

// Container Registry (Standard)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (deployContainerRegistry) {
  name: containerRegistryName
  location: location
  tags: commonTags
  sku: {
    name: 'Basic'
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

// ---------------------------------------------------------------------------
// Key Vault - Moved to database resource group for persistence
// ---------------------------------------------------------------------------

// Deploy Key Vault to the database resource group
module keyVaultModule 'keyvault.bicep' = {
  name: 'keyVaultDeployment'
  scope: resourceGroup(databaseResourceGroup) // This deploys to the DB resource group
  params: {
    name: keyVaultName
    location: location
    tags: commonTags
    tenantId: tenant().tenantId
    enablePurgeProtection: environment == 'production' || environment == 'prod'
    softDeleteRetentionInDays: environment == 'production' ? 90 : 30
  }
}

// Reference to the Key Vault for access policies and secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(databaseResourceGroup)
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

// Backend App Service (direct deployment)
module backendAppService './app-service.bicep' = if (useDirectDeployment) {
  name: 'backendAppService'
  params: {
    name: backendWebAppName
    location: location
    tags: commonTags
    appServicePlanId: appServicePlan.id
    pythonVersion: '3.11'
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    appInsightsConnectionString: appInsights.properties.ConnectionString
    databaseHost: db.outputs.fullyQualifiedDomainName
    databaseName: 'vigordb'
    databaseUser: postgresAdminUsername
    databasePassword: postgresAdminPassword
    secretKey: secretKey
    keyVaultName: keyVaultName
    keyVaultResourceGroupName: databaseResourceGroup
  }
}

// Legacy App Service (container-based) - kept for backward compatibility
resource appService 'Microsoft.Web/sites@2023-01-01' = if (!useDirectDeployment) {
  name: backendWebAppName
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

// Static Web App (Frontend) - New module for Static Web App
module frontendStaticWebApp './static-web-app.bicep' = if (useDirectDeployment) {
  name: 'frontendStaticWebApp'
  params: {
    name: staticWebAppName
    location: location
    tags: commonTags
    skuName: 'Standard'
    skuTier: 'Standard'
  }
}

// Legacy Static Web App (to maintain backward compatibility)
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = if (!useDirectDeployment) {
  name: frontendAppName
  location: 'Central US' // Use same region as other resources for consistency
  tags: commonTags
  sku: {
    name: 'Free' // Always use Free tier for cost optimization
  }
  properties: {}
}

// Function App for AI Processing (new component for serverless architecture)
module aiFunctionApp './function-app.bicep' = if (useDirectDeployment) {
  name: 'aiFunctionApp'
  params: {
    name: functionAppName
    location: location
    tags: commonTags
    appServicePlanId: appServicePlan.id
    appInsightsConnectionString: appInsights.properties.ConnectionString
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    storageAccountName: storageMod.outputs.storageAccountName
    storageAccountKey: storageMod.outputs.storageAccountKey
    keyVaultName: keyVaultName
    keyVaultResourceGroupName: databaseResourceGroup
    runtime: 'python'
    runtimeVersion: '3.11'
  }
}

// Deploy KeyVault secrets to the database resource group
module keyVaultSecretsModule 'keyvault-secrets.bicep' = {
  name: 'keyVaultSecretsDeployment'
  scope: resourceGroup(databaseResourceGroup)
  params: {
    keyVaultName: keyVaultName
    secretKeyValue: secretKey
    openaiApiKeyValue: openaiApiKey
    geminiApiKeyValue: geminiApiKey
    perplexityApiKeyValue: perplexityApiKey
  }
  dependsOn: [
    keyVaultModule
  ]
}

// Add App Service access policy to KeyVault in the database resource group
module appServiceKeyVaultAccess 'keyvault-access.bicep' = if (!useDirectDeployment) {
  name: 'appServiceKeyVaultAccess'
  scope: resourceGroup(databaseResourceGroup)
  params: {
    keyVaultName: keyVaultName
    principalId: appService.identity.principalId
    tenantId: tenant().tenantId
  }
  dependsOn: [
    keyVaultModule
    keyVaultSecretsModule
  ]
}

// Outputs
output resourceGroupName string = resourceGroup().name
output backendUrl string = useDirectDeployment
  ? 'https://${backendAppService.outputs.hostName}'
  : 'https://${appService.properties.defaultHostName}'
output frontendUrl string = useDirectDeployment
  ? 'https://${frontendStaticWebApp.outputs.staticWebAppUrl}'
  : 'https://${staticWebApp.properties.defaultHostname}'
output postgresServerFqdn string = db.outputs.fullyQualifiedDomainName
output keyVaultName string = keyVault.name
output containerRegistryLoginServer string = deployContainerRegistry ? containerRegistry.properties.loginServer : ''
output applicationInsightsConnectionString string = appInsights.properties.ConnectionString
