var resourceLocation = 'swedencentral'

module virtualHubNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-hub-global'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.0.0.0/24'
    ]
    name: 'hub-global'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.0.0/26'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.0.64/26'
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-globalBastion'
  params: {
    // Required parameters
    name: 'globalBastion'
    vNetId: virtualHubNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
  }
}
