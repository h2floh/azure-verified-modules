targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgnetwork 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-dns'
  location: resourceLocation
}

module dnstest './dns.bicep' = {
  scope: rgnetwork
  name: 'hubglobal'
  params: {
    resourceLocation: 'swedencentral'
    regionName: 'global'
    addressPrefix: '10.0.0.0/24' 
    addressPrefixBastion: '10.0.0.0/26'
    addressPrefixVM: '10.0.0.64/26'
    addressPrefixPrivateEndpoints: '10.0.0.128/26'
  }
}

