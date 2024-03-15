param networkIdsAndRegions array = []

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.4' = [for region in reduce(sort(map(networkIdsAndRegions, element => element.region), (a, b) => (a > b)), {}, (cur, next) => union(cur, next)): {
  name: '${uniqueString(deployment().name, 'global')}-test-${region}'
  params: {
    // Required parameters
    name: '${region}.internal.flow-soft.com'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      for networkIdAndRegionLink in networkIdsAndRegions : {
        virtualNetworkResourceId: networkIdAndRegionLink.networkid
        registrationEnabled: (networkIdAndRegionLink.region == region) ? 'True' : 'False'
      }
    ]
  }
}]
