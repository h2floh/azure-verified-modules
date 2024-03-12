var resourceLocation = 'swedencentral'

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
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId


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
        location: resourceLocation
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
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbayTrbSOQE+jlz+PzfJQzIHgATX2Gj+owdpD1/HHqtDrXMd6SqNlyf3/k0pYbCsXjA/A7MzJgAT1Kj5GwjGlDkIQA8kjVW9TByPDV+s//C6vTy1H6dE4jZYvTeolsm7JBkGOyTXI+pcL6vLkhzWIESxkeUG/LR08UPWVjcfk2Oqsk2I/AUiZxWhWcVIYasfJSHolrOHPcRdLNQoAY7iw3vrq4kw6DkcTVa9BTdxt0sym/j6TPMAJgA1z53ONt38PywIZ/Fb/dQer5QusOSJS4+rKR9gYHOAio3TWnmG7azERXpD2btD4OV4jvFhDx2EuFhRC4ZYLaPX5dnd4FIM2yhFi/zFWoCpYOSIZt21DMYr4qTZWP0arf/IL23ZkxssQlNTKlYdANfc1R0r7JMJO36/xZZq1h8N80MHKMyWWuXOYfGksrh617jqysOY20F09f0HpdES3oWN4vpRCWSAmDLyLnljg0Z20NTrKxDcCcAXj3vcZzxB+9UPnAQlfeX9c='
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}
