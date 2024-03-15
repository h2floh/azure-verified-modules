param resourceLocation string = 'swedencentral'

param regionName string = 'sweden'

module natGatewayPIP 'br/public:avm/res/network/public-ip-address:0.3.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-pip-nat-${regionName}'
  params: {
    // Required parameters
    name: 'pip-nat-${regionName}'
    // Non-required parameters
    location: resourceLocation
    skuTier: 'Regional'
    zones: [
      '1'
      '2'
      '3'
    ]
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:1.0.4' = {
  dependsOn: [
    natGatewayPIP
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-nat-${regionName}'
  params: {
    // Required parameters
    name: 'nat-${regionName}'
    // Non-required parameters
    location: resourceLocation
    publicIpResourceIds: [
      natGatewayPIP.outputs.resourceId
    ]
  }
}
