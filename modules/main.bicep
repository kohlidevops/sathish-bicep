targetScope = 'subscription'

param environment string
param location string

param landingZones object

@secure()
param vmAdminPassword string


// Resource Group
module rModule 'resourcegroup.bicep' = [
  for rg in landingZones.resourceGroups: {
    name: 'rg-${rg.rgName}-${rg.location}'
    scope: subscription()

    params: {
      rgname: rg.rgName
      location: rg.location
      tags: rg.tags
    }
  }
]


// VNETs
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


// Virtual Machines
module vmModule 'compute/vm.bicep' = [
  for vm in landingZones.vms: {
    name: 'vm-${vm.vmName}-${environment}-${location}'
    scope: resourceGroup(vm.resourceGroupName)

    dependsOn: [
      rModule
      vnetmodule
      keyvault
    ]

    params: {
      location: location
      vmName: vm.vmName
      vnetName: vm.vnetName
      subnetName: vm.subnetName
      adminUsername: vm.adminUsername
      vmAdminPassword: vmAdminPassword
      vmsize: vm.vmsize
      privateIPAllocationMethod: 'Dynamic'
      asgName: contains(vm, 'asgName') ? vm.asgName : ''
      tags: vm.tags
    }
  }
]


// NSG
module nsgModule 'networking/nsg.bicep' = [
  for nsg in landingZones.nsg: {
    name: 'nsg-${nsg.nsgName}-${environment}-${location}'
    scope: resourceGroup(nsg.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      location: nsg.location
      nsgName: nsg.nsgName
      securityRules: nsg.securityRules ?? []
    }
  }
]


// Route Tables
module routeTableModule 'networking/routetable.bicep' = [
  for rt in landingZones.routeTables: {
    name: 'rt-${rt.routeTableName}-${environment}-${location}'
    scope: resourceGroup(rt.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      routeTableName: rt.routeTableName
      location: rt.location
      disableBgpRoutePropagation: rt.disableBgpRoutePropagation
      routes: contains(rt, 'routes') ? rt.routes : []
    }
  }
]


// ASG
module asgModule 'networking/asg.bicep' = [
  for asg in landingZones.asgs: {
    name: 'asg-${asg.asgName}-${environment}-${location}'
    scope: resourceGroup(asg.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      location: location
      asgName: asg.asgName
    }
  }
]


// Storage Account
module storageModule 'storage/storageAccount.bicep' = [
  for st in landingZones.storageAccounts: {
    name: 'storage-${st.storageAccountName}-${environment}-${location}'
    scope: resourceGroup(st.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      storageAccountName: st.storageAccountName
      location: st.location
      tags: st.tags
    }
  }
]


// Key Vault
module keyvault 'security/keyvault.bicep' = [
  for kv in landingZones.keyVaults: {
    name: 'keyvault-${uniqueString(kv.keyVaultName)}'
    scope: resourceGroup(kv.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      keyVaultName: kv.keyVaultName
      location: kv.location
    }
  }
]


// VNET Peering
module peeringModule 'networking/vnetPeering.bicep' = [
  for peer in landingZones.peerings: {
    name: 'peering-${peer.peeringName}-${environment}-${location}'
    scope: resourceGroup(peer.sourceVnetResourceGroupName)

    dependsOn: [
      vnetmodule
    ]

    params: {
      peeringName: peer.peeringName
      sourceVnetName: peer.sourceVnetName
      remoteVnetName: peer.remoteVnetName
      remoteVnetResourceGroupName: peer.remoteVnetResourceGroupName
    }
  }
]


// Recovery Services Vault
module backupVaultModule 'backup/recoveryVault.bicep' = [
  for vault in landingZones.backupVaults: {
    name: 'rsv-${vault.vaultName}-${environment}-${location}'
    scope: resourceGroup(vault.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      vaultName: vault.vaultName
      location: vault.location
      sku: vault.sku
    }
  }
]


// Backup Policy
module backupPolicyModule 'backup/backupPolicy.bicep' = [
  for policy in landingZones.backupPolicies: {
    name: 'policy-${policy.policyName}-${environment}-${location}'
    scope: resourceGroup(policy.resourceGroupName)

    dependsOn: [
      backupVaultModule
    ]

    params: {
      policyName: policy.policyName
      vaultName: policy.vaultName
      backupTime: policy.backupTime
    }
  }
]


// Backup Protection
module vmBackupModule 'backup/backupProtection.bicep' = [
  for vm in landingZones.vmBackups: {
    name: 'backup-${vm.vmName}-${environment}-${location}'
    scope: resourceGroup(vm.resourceGroupName)

    dependsOn: [
      vmModule
      backupPolicyModule
    ]

    params: {
      vmName: vm.vmName
      vmResourceGroup: vm.resourceGroupName
      vaultName: vm.vaultName
      policyName: vm.policyName
    }
  }
]


// VNET Gateway
module vnetGatewayModule 'networking/vnetgateway.bicep' = [
  for gw in landingZones.vnetGateways: {
    name: 'vpngw-${gw.gatewayName}-${environment}-${location}'
    scope: resourceGroup(gw.resourceGroupName)

    dependsOn: [
      vnetmodule
    ]

    params: {
      gatewayName: gw.gatewayName
      location: gw.location
      vnetName: gw.vnetName
      gatewaySubnetName: gw.gatewaySubnetName
      gatewaySku: gw.gatewaySku
    }
  }
]


// Action Group
module actionGroupModule 'monitoring/actionGroup.bicep' = [
  for ag in landingZones.actionGroups: {
    name: 'ag-${ag.actionGroupName}-${environment}-${location}'
    scope: resourceGroup(ag.resourceGroupName)

    dependsOn: [
      rModule
    ]

    params: {
      actionGroupName: ag.actionGroupName
      emailReceivers: ag.emailReceivers
    }
  }
]


// Metric Alerts
module alertModule 'monitoring/metricAlert.bicep' = [
  for alert in landingZones.alerts: {
    name: 'alert-${alert.alertName}-${environment}-${location}'
    scope: resourceGroup(alert.resourceGroupName)

    dependsOn: [
      vmModule
      actionGroupModule
    ]

    params: {
      alertName: alert.alertName
      targetResourceName: alert.targetResourceName
      actionGroupName: alert.actionGroupName
      metricNamespace: alert.metricNamespace
      metricName: alert.metricName
      operator: alert.operator
      threshold: alert.threshold
      severity: alert.severity
      alertDescription: alert.alertDescription
    }
  }
]
