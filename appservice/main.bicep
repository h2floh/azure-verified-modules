targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgAppService 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-appservice'
  location: resourceLocation
}

module appservice './appservice.bicep' = {
  scope: rgAppService
  name: 'appservice'
  params: {
    resourceLocation: resourceLocation
    regionName: 'demo'
  }
}