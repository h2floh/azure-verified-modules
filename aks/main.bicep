targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgaks 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-aks'
  location: resourceLocation
}

module aks './aks.bicep' = {
  scope: rgaks
  name: 'aks'
  params: {
    resourceLocation: resourceLocation
    regionName: 'global'
    addressPrefix: '10.0.0.0/16'
    addressPrefixAks: '10.0.1.0/24'
    addressPrefixBastion: '10.0.0.0/26'
    addressPrefixVM: '10.0.0.64/26'
    addressPrefixPrivateEndpoints: '10.0.0.128/26'
  }
}