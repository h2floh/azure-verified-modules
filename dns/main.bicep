targetScope = 'subscription'

param resourceLocation string = 'swedencentral'
param publicKey string = ''

resource rgdnsprime 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-dns-primary'
  location: resourceLocation
}

resource rgdnssec 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-dns-secondary'
  location: resourceLocation
}

module dnstest './dns.bicep' = {
  scope: rgdnsprime
  name: 'dnsprime'
  params: {
    main: true
    resourceLocation: 'swedencentral'
    regionName: 'A'
    publicKey: publicKey
    addressPrefix: '10.0.0.0/24' 
    addressPrefixBastion: '10.0.0.0/26'
    addressPrefixVM: '10.0.0.64/26'
    addressPrefixPrivateEndpoints: '10.0.0.128/26'
  }
}

module dnstest2 './dns.bicep' = {
  scope: rgdnssec
  name: 'dnssec'
  params: {
    main: false
    resourceLocation: 'swedencentral'
    regionName: 'B'
    publicKey: publicKey
    addressPrefix: '10.0.0.0/24' 
    addressPrefixBastion: '10.0.0.0/26'
    addressPrefixVM: '10.0.0.64/26'
    addressPrefixPrivateEndpoints: '10.0.0.128/26'
  }
}

module storageAccountPublic 'br/public:avm/res/storage/storage-account:0.6.0' = {
  scope: rgdnsprime
  name: '${uniqueString(deployment().name, resourceLocation)}-storageaccount-public'
  params: {
    // Required parameters
    name: 'pub${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: resourceLocation
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: true
  }
}
