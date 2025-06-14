// KeyVault secrets module
param keyVaultName string

@secure()
param secretKeyValue string

@secure()
param openaiApiKeyValue string = ''

@secure()
param geminiApiKeyValue string = ''

@secure()
param perplexityApiKeyValue string = ''

// Reference to existing KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Set up access policy for deployment
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: keyVault.properties.tenantId
        objectId: '00000000-0000-0000-0000-000000000000' // This will be replaced with the actual deployment identity
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
    ]
  }
}

// Create required secrets
resource secretKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'secret-key'
  properties: {
    value: secretKeyValue
  }
}

// Create optional API key secrets if provided
resource openaiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(openaiApiKeyValue)) {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openaiApiKeyValue
  }
}

resource geminiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(geminiApiKeyValue)) {
  parent: keyVault
  name: 'gemini-api-key'
  properties: {
    value: geminiApiKeyValue
  }
}

resource perplexityApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(perplexityApiKeyValue)) {
  parent: keyVault
  name: 'perplexity-api-key'
  properties: {
    value: perplexityApiKeyValue
  }
}
