// Database module for Vigor
// Deploys PostgreSQL flexible server and database

param location string
param environment string
param postgresServerName string
param postgresAdminUsername string
@secure()
param postgresAdminPassword string

var commonTags = {
  Environment: environment
  ManagedBy: 'bicep'
  Component: 'database'
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '14'
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: environment == 'production' ? 'ZoneRedundant' : 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresServer
  name: 'vigor_db'
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

output fullyQualifiedDomainName string = postgresServer.properties.fullyQualifiedDomainName
