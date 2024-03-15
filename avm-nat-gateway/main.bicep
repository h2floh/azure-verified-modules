targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgnetwork 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-avm-nat-gateway-bug'
  location: resourceLocation
}

module hubSpokeSweden './hubSpoke.bicep' = {
  scope: rgnetwork
  name: 'hubSweden'
  params: {
    resourceLocation: 'swedencentral'
    regionName: 'sweden'
  }
}

module hubSpokePoland './hubSpoke.bicep' = {
  scope: rgnetwork
  name: 'hubPoland'
  params: {
    // 10.4.0.0/14 for whole region
    resourceLocation: 'polandcentral'
    regionName: 'poland'
  }
}
