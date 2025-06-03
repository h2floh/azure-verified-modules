param resourceLocation string = 'westeurope'
param regionName string = 'global'
param addressPrefixVnet string = '10.1.0.0/16'
param addressPrefixAks string = '10.1.0.0/24'
param addressPrefixServices string = '10.1.1.0/24'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-network-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixVnet
    ]
    name: 'vnet-aks-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AksSubnet'
        addressPrefix: addressPrefixAks
      }
      {
        name: 'ServicesSubnet'
        addressPrefix: addressPrefixServices
      }
    ]
  }
}

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.2.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-aks-${regionName}'
  params: {
    // Required parameters
    name: 'aks-${regionName}'
    // Non-required parameters
    location: resourceLocation
    managedIdentities: {
      systemAssigned: true
    }
    primaryAgentPoolProfile: [
      {
        name: 'system'
        vmSize: 'Standard_B2s'
        count: 1
        maxCount: 3
        minCount: 1
        enableAutoScaling: true
        vnetSubnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
    }
    tags: {
      Environment: 'Development'
      Service: 'AKS'
      Region: regionName
    }
  }
}

output aksClusterName string = aksCluster.outputs.name
output aksClusterResourceId string = aksCluster.outputs.resourceId
output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId