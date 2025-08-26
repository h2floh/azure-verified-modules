targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgAppService 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-appservice-windows'
  location: resourceLocation
}

module appservice './appservice-windows.bicep' = {
  scope: rgAppService
  name: 'appservice-windows'
  params: {
    resourceLocation: resourceLocation
    regionName: 'demo'
  }
}