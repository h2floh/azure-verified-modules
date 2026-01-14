param resourceLocation string = 'swedencentral'

param regionName string = 'swedencentral'

param publicKey string

param main bool = true
param addressPrefix string = '10.0.0.0/24' 
param addressPrefixBastion string = '10.0.0.0/26'
param addressPrefixVM string = '10.0.0.64/26'
param addressPrefixPrivateEndpoints string = '10.0.0.128/26'
param addressPrefixDNS string = '10.0.0.192/28'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-${regionName}'
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
      {
        name: 'DNS'
        addressPrefix: addressPrefixDNS
        delegations: [
          {
            name: 'dnsResolvers'
            properties: {
              serviceName: 'Microsoft.Network/dnsResolvers'
            }
          }
        ]
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = if (main) {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Bastion'
  params: {
    // Required parameters
    name: '${regionName}Bastion'
    vNetId: virtualNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.1.0' = if (main) {
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
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
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
        // sample content of publicKey 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr...'
        keyData: publicKey
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

module privateDnsZoneBlob 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-zone-${regionName}'
  params: {
    // Required parameters
    name: 'privatelink.blob.core.windows.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
        registrationEnabled: false
      } 
    ]
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.6.7' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-storageaccount'
  params: {
    // Required parameters
    name: '${toLower(regionName)}${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: resourceLocation
    skuName: 'Standard_LRS'
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDnsZoneBlob.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[2]
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
}

var dnsResolverName = '${regionName}-dnsresolver'
module dnsResolver 'br/public:avm/res/network/dns-resolver:0.3.0' = if (main) {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-dnsresolver'
  params: {
    // Required parameters
    name: '${regionName}-dnsresolver'
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    location: resourceLocation
    outboundEndpoints: [
      {
        name: 'ndrmax-az-pdnsout-x-001'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[3]
      }
    ]
  }
}

module dnsForwardingRuleset 'br/public:avm/res/network/dns-forwarding-ruleset:0.2.5' = if (main) {
  dependsOn: [
    dnsResolver
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-dnsForwardingRulesetDeployment'
  params: {
    // Required parameters
    dnsForwardingRulesetOutboundEndpointResourceIds: [
      resourceId('Microsoft.Network/dnsResolvers/outboundEndpoints', dnsResolverName, 'ndrmax-az-pdnsout-x-001')
    ]
    name: 'dnsfrs001'

    // Non-required parameters
    forwardingRules: [
      {
        domainName: 'tobereplaced.blob.core.windows.net.'
        forwardingRuleState: 'Enabled'
        name: 'toPublic'
        targetDnsServers: [
          {
            ipAddress: '8.8.8.8'
            port: '53'
          }
        ]
      }
    ]
    location: resourceLocation
    virtualNetworkLinks: [
      {
        name: 'vnetlink1'
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
      }
    ]
  }
}
