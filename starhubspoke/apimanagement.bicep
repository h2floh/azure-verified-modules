param regionAndHubNetworkId array = [
  {
    regionname: 'test'
    location: 'westeurope'
    subnetid: '/subscription/.../'
  }
]

module service 'br/public:avm/res/api-management/service:0.1.0' = {
  name: '${uniqueString(deployment().name, regionAndHubNetworkId[0].location)}-apim-${regionAndHubNetworkId[0].region}'
  params: {
    // Required parameters
    name: 'apim-global'
    publisherEmail: 'florian.wagner@devoteam.com'
    publisherName: 'flwagnerdevoteam'
    // Non-required parameters
    additionalLocations: [for rahnid in skip(regionAndHubNetworkId, 1) :{
        disableGateway: true
        location: rahnid.location
        natGatewayState: false
        publicIpAddressId: rahnid.publicIpId
        sku: {
          capacity: 1
          name: 'Developer'
        }
        virtualNetworkConfiguration: {
          subnetResourceId: rahnid.subnetid
        }
        // zones: [
        //   'string'
        // ]
      }
    ]
    location: regionAndHubNetworkId[0].location
    managedIdentities: {
      systemAssigned: true
    }
    sku: 'Developer'
    skuCount: 1
    virtualNetworkType: 'External'
    customProperties: {
      publicIpAddressId: regionAndHubNetworkId[0].publicIpId
    }
    subnetResourceId: regionAndHubNetworkId[0].subnetid
    // zones: [
    //   'string'
    // ]
  }
}
