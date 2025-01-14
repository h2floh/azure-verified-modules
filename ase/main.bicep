targetScope = 'subscription'

param resourceLocation string = 'italynorth'

resource rgase 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-ase'
  location: resourceLocation
}

module ase './ase.bicep' = {
  scope: rgase
  name: 'ase'
  params: {
    resourceLocation: resourceLocation
    regionName: 'global'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    addressPrefixHub: '10.0.0.0/24' 
    addressPrefixApplicationGateway: '10.0.0.192/26'
    applicationGatewayIpAdress: '10.0.0.196'
    adressPrefixASE: '10.0.0.0/25'
    addressPrefixBastion: '10.0.0.128/29'
  }
}

