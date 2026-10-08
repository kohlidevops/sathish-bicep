param location string
param adminUsername string
param vmsize string
param privateIPAllocationMethod string

@secure()
param vmAdminPassword string

param vmName string
param tags object
param subnetName string
param vnetName string

@description('Optional ASG Name')
param asgName string = ''

output vmId string = vm.id
output vmNameOut string = vm.name


resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'

        properties: {
          subnet: {
            id: existingSubnet.id
          }

          privateIPAllocationMethod: privateIPAllocationMethod

          applicationSecurityGroups: empty(asgName)
            ? null
            : [
                {
                  id: existingAsg.id
                }
              ]
        }
      }
    ]
  }
}


resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags

  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }

    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: vmAdminPassword
    }

    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}


resource existingVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}


resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  parent: existingVnet
  name: subnetName
}


resource existingAsg 'Microsoft.Network/applicationSecurityGroups@2023-04-01' existing = if (!empty(asgName)) {
  name: asgName
}
