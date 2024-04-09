param networkIdsAndRegions array = [
  {
    region: 'eastus'
    networkid: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-az-00000000/providers/Microsoft.Network/virtualNetworks/vnet-avm-az-00000000'
  }
]
param keyvaults array = [
  {
    keyvaultName: 'kv-avm-az-00000000'
    privateEndpointName: 'pe-avm-az-00000000'
  }
]
module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.4' = [for region in reduce(map(networkIdsAndRegions, element => [element.region]), [], (cur, next) => union(cur, next)): {
  name: '${uniqueString(deployment().name, 'global')}-dns-regions-${region}'
  params: {
    // Required parameters
    name: '${region}.flow-soft.internal'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      for networkIdAndRegionLink in networkIdsAndRegions : {
        virtualNetworkResourceId: networkIdAndRegionLink.networkid
        registrationEnabled: (networkIdAndRegionLink.region == region) ? true : false
      }
    ]
  }
}]


resource pepoints 'Microsoft.Network/privateEndpoints@2023-04-01' existing = [for keyvaultIp in keyvaults : {
  name: keyvaultIp.privateEndpointName
}]

// output pe array = [
//   for (keyvaultIp, index) in keyvaults : {
//     name: pepoints[index].name
//     properties: pepoints[index].properties
//   }
// ]

module privateDnsZoneKeyVault 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  dependsOn: [
    pepoints
  ]
  name: '${uniqueString(deployment().name, 'global')}-dns-keyvault-global'
  params: {
    // Required parameters
    name: 'privatelink.vaultcore.azure.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      for networkIdAndRegionLink in networkIdsAndRegions : {
        virtualNetworkResourceId: networkIdAndRegionLink.networkid
        registrationEnabled: false
      }
    ]
    a: [
      for (keyvaultIp, index) in keyvaults : {
        aRecords: [
          {
            ipv4Address: pepoints[index].properties.customDnsConfigs[0].ipAddresses[0]
          }
        ]
        name: keyvaultIp.keyvaultName
        ttl: 3600
      }
    ]
  }
}
