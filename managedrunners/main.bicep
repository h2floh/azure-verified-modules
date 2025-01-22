targetScope = 'subscription'

param resourceLocation string = 'italynorth'
param peeringNetworkId string = '/subscriptions/1cf7c47a-9984-4a46-9b6d-45dd6e2e4ae3/resourceGroups/rg-managedrunners/providers/Microsoft.Network/virtualNetworks/vnet-runners'

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
      mainResources.outputs.networkIdsAndRegions
    )
    keyvaults: concat(
      mainResources.outputs.keyvaults
    )
  }
}
