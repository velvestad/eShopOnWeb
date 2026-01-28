// Bicep file to create a Storage Account and a Virtual Network with two subnets

param location string = resourceGroup().location
param storageAccountName string = 'storage-account-${uniqueString(resourceGroup().id)}'

param vmAdminUsername string = 'adminUser'

@secure()
param vmAdminSecureStringPassword string


resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'virtual-network-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${virtualNetwork.id}/subnets/subnet-1'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'windows-vm-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: 'VM-1'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminSecureStringPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'windows-vm-osdisk-${uniqueString(resourceGroup().id)}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
networkProfile: {
  networkInterfaces: [
    {
      id: networkInterface.id // Reference to the created network interface
    }
  ]
}
diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}
