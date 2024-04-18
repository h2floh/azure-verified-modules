param resourceLocation string = 'swedencentral'

param regionName string = 'swedencentral'

param addressPrefix string = '10.0.0.0/24' 
param addressPrefixBastion string = '10.0.0.0/26'
param addressPrefixVM string = '10.0.0.64/26'
param addressPrefixPrivateEndpoints string = '10.0.0.128/26'

module virtualNetworkMain 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-main-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefix
    ]
    name: 'dns-vnet-connected-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixBastion
        // No route table can be attached
      }
      {
        name: 'VMSubnet'
        addressPrefix: addressPrefixVM
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: addressPrefixPrivateEndpoints
      }
    ]
  }
}

module virtualNetworkDisconnected 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-disconnected-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefix
    ]
    name: 'dns-vnet-disconnected-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: addressPrefixPrivateEndpoints
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Bastion'
  params: {
    // Required parameters
    name: '${regionName}Bastion'
    vNetId: virtualNetworkMain.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
  }
}

module virtualMachineA 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  dependsOn: [
    virtualNetworkMain
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: '${regionName}-vm'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: virtualNetworkMain.outputs.subnetResourceIds[1]
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
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbayTrbSOQE+jlz+PzfJQzIHgATX2Gj+owdpD1/HHqtDrXMd6SqNlyf3/k0pYbCsXjA/A7MzJgAT1Kj5GwjGlDkIQA8kjVW9TByPDV+s//C6vTy1H6dE4jZYvTeolsm7JBkGOyTXI+pcL6vLkhzWIESxkeUG/LR08UPWVjcfk2Oqsk2I/AUiZxWhWcVIYasfJSHolrOHPcRdLNQoAY7iw3vrq4kw6DkcTVa9BTdxt0sym/j6TPMAJgA1z53ONt38PywIZ/Fb/dQer5QusOSJS4+rKR9gYHOAio3TWnmG7azERXpD2btD4OV4jvFhDx2EuFhRC4ZYLaPX5dnd4FIM2yhFi/zFWoCpYOSIZt21DMYr4qTZWP0arf/IL23ZkxssQlNTKlYdANfc1R0r7JMJO36/xZZq1h8N80MHKMyWWuXOYfGksrh617jqysOY20F09f0HpdES3oWN4vpRCWSAmDLyLnljg0Z20NTrKxDcCcAXj3vcZzxB+9UPnAQlfeX9c='
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

module privateDnsZoneBlobConnected 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-connected-${regionName}'
  params: {
    // Required parameters
    name: 'privatelink.blob.core.windows.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      virtualNetworkMain.outputs.resourceId
    ]
  }
}


module storageAccountConnected 'br/public:avm/res/storage/storage-account:0.6.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-storageaccount-connected'
  params: {
    // Required parameters
    name: 'conn${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: resourceLocation
    skuName: 'Standard_LRS'
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDnsZoneBlobConnected.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: virtualNetworkMain.outputs.subnetResourceIds[2]
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
}

module privateDnsZoneBlobDisconnected 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-disconnected-${regionName}'
  params: {
    // Required parameters
    name: 'privatelink.blob.core.windows.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      virtualNetworkDisconnected.outputs.resourceId
    ]
  }
}

module storageAccountDisconnected 'br/public:avm/res/storage/storage-account:0.6.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-storageaccount-disconnected'
  params: {
    // Required parameters
    name: 'disco${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: resourceLocation
    skuName: 'Standard_LRS'
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDnsZoneBlobDisconnected.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: virtualNetworkDisconnected.outputs.subnetResourceIds[0]
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
}

module storageAccountPublic 'br/public:avm/res/storage/storage-account:0.6.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-storageaccount-disconnected'
  params: {
    // Required parameters
    name: 'pub${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: resourceLocation
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Enabled'
  }
}
