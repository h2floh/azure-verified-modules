param resourceLocation string = 'swedencentral'

param peeringNetworks array = []

module virtualHubNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-hub-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.8.0.0/24' // 10.8.0.0/14 for whole region
    ]
    name: 'hub-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      for peeringNetwork in peeringNetworks: {
        remoteVirtualNetworkId: peeringNetwork.remoteVirtualNetworkId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.8.0.0/26'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.8.0.64/26'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.8.0.128/26'
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-swedenBastion'
  params: {
    // Required parameters
    name: 'swedenBastion'
    vNetId: virtualHubNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
  }
}

module azfwmgmtip 'br/public:avm/res/network/public-ip-address:0.3.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-swedenFirewall'
  params: {
    // Required parameters
    name: 'azfwmgmtip-sweden'
    // Non-required parameters
    location: resourceLocation
  }
}

resource azfw 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  dependsOn: [
    azfwmgmtip
    virtualHubNetwork
  ]
  name: 'swedenFirewall'
  location: resourceLocation
  properties: {
    threatIntelMode: 'Alert'
    hubIPAddresses: {
      privateIPAddress: '10.8.0.65'
    }
    ipConfigurations: [
      {
        id: 'internal'
        name: 'internal'
        properties: {
          subnet: {
            id: virtualHubNetwork.outputs.subnetResourceIds[1]
          }
        }
      }
    ]
    managementIpConfiguration: {
      id: 'external'
      name: 'external'
      properties: {
        publicIPAddress: {
          id: azfwmgmtip.outputs.resourceId
        }
        subnet: {
          id: virtualHubNetwork.outputs.subnetResourceIds[2]
        }
      }
    }
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
  }
}


module spokea 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-a-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.8.16.0/20'
    ]
    name: 'spoke-b-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      {
        remoteVirtualNetworkId: virtualHubNetwork.outputs.resourceId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'subnet-a'
        addressPrefix: '10.8.16.0/24'
      }
      {
        name: 'subnet-b'
        addressPrefix: '10.8.17.0/24'
      }
    ]
  }
}

module spokeb 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-b-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.8.32.0/20'
    ]
    name: 'spoke-a-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      {
        remoteVirtualNetworkId: virtualHubNetwork.outputs.resourceId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'subnet-a'
        addressPrefix: '10.8.32.0/24'
      }
      {
        name: 'subnet-b'
        addressPrefix: '10.8.33.0/24'
      }
    ]
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-sweden-vm'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'sweden-vm'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: spokeb.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
        enablePublicIP: false
        enableAcceleratedNetworking: false // Accelerated Networking is not supported for B1s
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '32'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B1s'
    // encryptionAtHost: true // default true if not working use 'az feature register --name EncryptionAtHost --namespace Microsoft.Compute'
    // Non-required parameters
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: 'ssh-rsa ***REMOVED***'
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}
