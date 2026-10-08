@description('Azure SQL Server name. Must be globally unique.')
param sqlServerName string

@description('Azure SQL Database name.')
param sqlDatabaseName string

@description('Azure region for the SQL Server.')
param location string

@description('SQL administrator login name.')
param administratorLogin string

@secure()
@description('SQL administrator password.')
param administratorLoginPassword string

@description('SQL Database SKU name.')
param databaseSkuName string = 'Basic'

@description('SQL Database maximum size in bytes.')
param databaseMaxSizeBytes int = 2147483648

@description('SQL Server minimum TLS version.')
param minimalTlsVersion string = '1.2'

@description('Allow public network access to the SQL Server.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Resource tags.')
param tags object = {}


resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags

  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: publicNetworkAccess
  }
}


resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location

  sku: {
    name: databaseSkuName
  }

  properties: {
    maxSizeBytes: databaseMaxSizeBytes
  }
}


output sqlServerId string = sqlServer.id
output sqlServerNameOut string = sqlServer.name
output sqlDatabaseId string = sqlDatabase.id
output sqlDatabaseNameOut string = sqlDatabase.name
