@description('Azure Container Registry name. Must be globally unique.')
param registryName string

@description('Azure region for the Container Registry.')
param location string

@description('Container Registry SKU.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Resource tags.')
param tags object = {}


resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }

  properties: {
    adminUserEnabled: false
  }

  tags: tags
}


output registryId string = acr.id
output registryNameOut string = acr.name
output loginServer string = acr.properties.loginServer
