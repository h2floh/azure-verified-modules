targetScope = 'subscription'

param resourceLocation string = 'westeurope'

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
    addressPrefixVnet: '10.1.0.0/16'
    addressPrefixAks: '10.1.0.0/24'
    addressPrefixServices: '10.1.1.0/24'
  }
}