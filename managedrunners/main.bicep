targetScope = 'subscription'

param resourceLocation string = 'italynorth'

// Network of the GitHub Runners
param peeringNetworkRegion string = 'swedencentral'
param peeringNetworkId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-az-00000000/providers/Microsoft.Network/virtualNetworks/vnet-avm-az-00000000'

resource rgrunnerdemo 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-managedrunnerdemo'
  location: resourceLocation
}

module mainResources './network.bicep' = {
  scope: rgrunnerdemo
  name: 'internal'
  params: {
    resourceLocation: resourceLocation
    regionName: 'internal'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    addressPrefixHub: '10.0.0.0/24' 
    addressPrefixApplicationGateway: '10.0.0.192/26'
    applicationGatewayIpAdress: '10.0.0.196'
    adressPrefixPrivateLink: '10.0.0.0/25'
    addressPrefixBastion: '10.0.0.128/29'
    peeringNetworkId: peeringNetworkId
  }
}


module privateDNS './privateDNS.bicep' = {
  scope: rgrunnerdemo
  name: 'privateDNS'
  params: {
    networkIdsAndRegions: concat(
      mainResources.outputs.networkIdsAndRegions,
      [{
        region: peeringNetworkRegion
        networkid: peeringNetworkId
      }]
    )
    keyvaults: concat(
      mainResources.outputs.keyvaults
    )
  }
}
