param resourceLocation string = 'eastus'
param regionName string = 'aks'
param addressPrefixHub string = '10.1.0.0/16'
param addressPrefixAKS string = '10.1.1.0/24'
param addressPrefixBastion string = '10.1.0.0/26'
param addressPrefixPrivateEndpoints string = '10.1.0.64/26'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-network-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixHub
    ]
    name: 'vnet-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixBastion
        // No route table can be attached
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: addressPrefixPrivateEndpoints
      }
      {
        name: 'AKSSubnet'
        addressPrefix: addressPrefixAKS
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
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

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-umsi'
  params: {
    // Required parameters
    name: '${regionName}-umsi'
    // Non-required parameters
    location: resourceLocation
  }
}

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.2.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-aks-${regionName}'
  params: {
    // Required parameters
    name: 'aks-${regionName}'
    // Non-required parameters
    location: resourceLocation
    managedIdentities: {
      userAssignedResourceIds: [userAssignedIdentity.outputs.resourceId]
    }
    agentPools: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_B2s'
        mode: 'System'
        vnetSubnetResourceId: virtualNetwork.outputs.subnetResourceIds[2]
        maxPods: 30
        enableAutoScaling: false
        osType: 'Linux'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
    }
    dnsPrefix: 'aks-${regionName}-dns'
    enableRBAC: true
  }
}