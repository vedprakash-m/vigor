// Static Web App module for Vigor Frontend
param name string
param location string
param tags object
param skuName string = 'Standard'
param skuTier string = 'Standard'

// Static Web App resource
resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    // Provider is GitHub as we're using GitHub Actions
    provider: 'GitHub'
    stagingEnvironmentPolicy: 'Disabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Enabled'
  }
}

output staticWebAppId string = staticWebApp.id
output staticWebAppName string = staticWebApp.name
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
