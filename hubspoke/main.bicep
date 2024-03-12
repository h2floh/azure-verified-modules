targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgnetwork 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-network'
  location: resourceLocation
}

module hubglobal './globalHub.bicep' = {
  scope: rgnetwork
  name: 'hubglobal'
}

module hubSpokeSweden './hubSpokeSwedenCentral.bicep' = {
  scope: rgnetwork
  name: 'hubSweden'
  params: {
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}

module hubSpokePoland './hubSpokePolandCentral.bicep' = {
  scope: rgnetwork
  name: 'hubPoland'
  params: {
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}
