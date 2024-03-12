var resourceLocation = 'polandcentral'

param peeringNetworks array = []

module virtualHubNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-hub-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.4.0.0/24' // 10.4.0.0/14 for whole region
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
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

module spokea 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-a-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.4.16.0/20'
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
        addressPrefix: '10.4.16.0/24'
      }
      {
        name: 'subnet-b'
        addressPrefix: '10.4.17.0/24'
      }
    ]
  }
}

module spokeb 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-b-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.4.32.0/20'
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
        addressPrefix: '10.4.32.0/24'
      }
      {
        name: 'subnet-b'
        addressPrefix: '10.4.33.0/24'
      }
    ]
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-poland-vm'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'poland-vm'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: spokea.outputs.subnetResourceIds[0]
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
