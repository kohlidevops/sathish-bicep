module vnetmodule 'networking/vnet.bicep' = [
  for vnet in landingZones.vnets: {
    name: 'vnet-${vnet.vnetName}-${environment}-${location}'
    scope: resourceGroup(vnet.resourceGroupName)

    dependsOn: [
      rModule
      nsgModule
    ]

    params: {
      vnetName: vnet.vnetName
      location: vnet.location
      addressPrefixes: vnet.addressPrefixes
      subnets: vnet.subnets
      tags: vnet.tags
    }
  }
]
