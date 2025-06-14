// Key Vault module for the database resource group
param name string
param location string
param tags object
param tenantId string
param enablePurgeProtection bool = true
param softDeleteRetentionInDays int = 90

// Key Vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: 'Enabled' // Temporarily enabled during deployment
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    accessPolicies: []
  }
}

// Output the vault name and resource ID
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
