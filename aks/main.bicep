targetScope = 'subscription'

param resourceLocation string = 'eastus'

resource rgaks 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-aks'
  location: resourceLocation
}

module aks './aks.bicep' = {
  scope: rgaks
  name: 'aks'
  params: {
    resourceLocation: resourceLocation
    regionName: 'aks'
    addressPrefixHub: '10.1.0.0/16' 
    addressPrefixAKS: '10.1.1.0/24'
    addressPrefixBastion: '10.1.0.0/26'
    addressPrefixPrivateEndpoints: '10.1.0.64/26'
  }
}