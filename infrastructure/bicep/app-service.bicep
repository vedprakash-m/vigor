// App Service module for direct deployment (non-container)
param name string
param location string
param tags object
param appServicePlanId string
param pythonVersion string = '3.11'
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param databaseHost string
param databaseName string
param databaseUser string
@secure()
param databasePassword string
@secure()
param secretKey string
param keyVaultName string
param keyVaultResourceGroupName string

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

// App Service (Web App)
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|${pythonVersion}'
      alwaysOn: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'DATABASE_HOST'
          value: databaseHost
        }
        {
          name: 'DATABASE_NAME'
          value: databaseName
        }
        {
          name: 'DATABASE_USER'
          value: databaseUser
        }
        {
          name: 'DATABASE_PASSWORD'
          value: databasePassword
        }
        {
          name: 'SECRET_KEY'
          value: secretKey
        }
        {
          name: 'OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/openai-api-key/)'
        }
        {
          name: 'GEMINI_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/gemini-api-key/)'
        }
        {
          name: 'PERPLEXITY_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/perplexity-api-key/)'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'FUNCTIONS_API_URL'
          value: 'https://vigor-ai-functions.azurewebsites.net'
        }
        {
          name: 'PORT'
          value: '8000'
        }
        {
          name: 'WEBSITE_HTTPSCALEV2_ENABLED'
          value: '1'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
      ]
      healthCheckPath: '/api/health'
    }
  }
}

// Add KeyVault access policy for the App Service
module appServiceKeyVaultAccess './keyvault-access.bicep' = {
  name: 'appServiceKeyVaultAccess-${name}'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: appService.identity.principalId
    tenantId: appService.identity.tenantId
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output hostName string = appService.properties.defaultHostName
output principalId string = appService.identity.principalId
