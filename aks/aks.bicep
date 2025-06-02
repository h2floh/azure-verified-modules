param resourceLocation string = 'swedencentral'
param regionName string = 'global'
param addressPrefix string = '10.0.0.0/16' 
param addressPrefixAKS string = '10.0.1.0/24'
param addressPrefixVM string = '10.0.0.0/24'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-aks-vnet-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefix
    ]
    name: 'aks-vnet-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AKSSubnet'
        addressPrefix: addressPrefixAKS
      }
      {
        name: 'VMSubnet'
        addressPrefix: addressPrefixVM
      }
    ]
  }
}

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.2.6' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-aks-${regionName}'
  params: {
    // Required parameters
    name: 'aks-cluster-${regionName}'
    // Non-required parameters
    location: resourceLocation
    primaryAgentPoolProfile: [
      {
        name: 'systempool'
        vmSize: 'Standard_DS2_v2'
        count: 1
        mode: 'System'
        vnetSubnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
    agentPools: [
      {
        name: 'userpool'
        vmSize: 'Standard_DS2_v2'
        count: 2
        mode: 'User'
        vnetSubnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
    managedIdentities: {
      systemAssigned: true
    }
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
    }
    enableRBAC: true
    aadProfile: {
      managed: true
    }
  }
}

output aksClusterId string = aksCluster.outputs.resourceId
output aksClusterName string = aksCluster.outputs.name
output vnetId string = virtualNetwork.outputs.resourceId