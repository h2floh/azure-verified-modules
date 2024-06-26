targetScope = 'subscription'

param resourceLocation string = 'swedencentral'

resource rgnetwork 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-network'
  location: resourceLocation
}

module hubglobal './globalHub.bicep' = {
  scope: rgnetwork
  name: 'hubglobal'
  params: {
    resourceLocation: 'swedencentral'
    regionName: 'global'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    addressPrefixHub: '10.0.0.0/24' 
    addressPrefixHubBastion: '10.0.0.0/26'
    addressPrefixHubFirewall: '10.0.0.64/26'
    firewallIpAdress: '10.0.0.68'
    addressPrefixHubFirewallManagement: '10.0.0.128/26'
    addressPrefixApplicationGateway: '10.0.0.192/26'
    applicationGatewayIpAdress: '10.0.0.196'
    polandAddressPrefix: '10.4.0.0/14'
    polandFirewallIpAddress: '10.4.0.68'
    swedenAddressPrefix: '10.8.0.0/14'
    swedenFirewallIpAddress: '10.8.0.68'
  }
}

module hubSpokeSweden './hubSpoke.bicep' = {
  scope: rgnetwork
  name: 'hubSweden'
  params: {
    // 10.8.0.0/14 for whole region
    resourceLocation: 'swedencentral'
    regionName: 'sweden'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    globalFirewallAddress: '10.0.0.68'
    addressPrefixRegion: '10.8.0.0/14'
    addressPrefixHub: '10.8.0.0/24'
    addressPrefixHubBastion: '10.8.0.0/26'
    addressPrefixHubFirewall: '10.8.0.64/26'
    firewallIpAdress: '10.8.0.68'
    addressPrefixHubFirewallManagement: '10.8.0.128/26'
    addressPrefixApplicationGateway: '10.8.0.192/27'
    applicationGatewayIpAdress: '10.8.0.196'
    addressPrefixAPIManagement: '10.8.0.224/27'
    addressPrefixSpokeA: '10.8.16.0/20'
    addressPrefixSpokeASubnetA: '10.8.16.0/24'
    addressPrefixSpokeASubnetB: '10.8.17.0/24'
    addressPrefixSpokeASubnetC: '10.8.18.0/24'
    addressPrefixSpokeB: '10.8.32.0/20'
    addressPrefixSpokeBSubnetA: '10.8.33.0/24'
    addressPrefixSpokeBSubnetB: '10.8.34.0/24'
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}

module hubSpokePoland './hubSpoke.bicep' = {
  dependsOn: [
    hubSpokeSweden
  ]
  scope: rgnetwork
  name: 'hubPoland'
  params: {
    // 10.4.0.0/14 for whole region
    resourceLocation: 'polandcentral'
    regionName: 'poland'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    globalFirewallAddress: '10.0.0.68'
    addressPrefixRegion: '10.4.0.0/14'
    addressPrefixHub: '10.4.0.0/24'
    addressPrefixHubBastion: '10.4.0.0/26'
    addressPrefixHubFirewall: '10.4.0.64/26'
    firewallIpAdress: '10.4.0.68'
    addressPrefixHubFirewallManagement: '10.4.0.128/26'
    addressPrefixApplicationGateway: '10.4.0.192/27'
    applicationGatewayIpAdress: '10.4.0.196'
    addressPrefixAPIManagement: '10.4.0.224/27'
    addressPrefixSpokeA: '10.4.16.0/20'
    addressPrefixSpokeASubnetA: '10.4.16.0/24'
    addressPrefixSpokeASubnetB: '10.4.17.0/24'
    addressPrefixSpokeASubnetC: '10.4.18.0/24'
    addressPrefixSpokeB: '10.4.32.0/20'
    addressPrefixSpokeBSubnetA: '10.4.33.0/24'
    addressPrefixSpokeBSubnetB: '10.4.34.0/24'
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}

module privateDNS './privateDNS.bicep' = {
  dependsOn: [
    hubglobal
    hubSpokeSweden
    hubSpokePoland
  ]
  scope: rgnetwork
  name: 'privateDNS'
  params: {
    networkIdsAndRegions: concat(
      hubglobal.outputs.networkIdsAndRegions,
      hubSpokePoland.outputs.networkIdsAndRegions,
      hubSpokeSweden.outputs.networkIdsAndRegions
    )
    keyvaults: concat(
      hubSpokePoland.outputs.keyvaults,
      hubSpokeSweden.outputs.keyvaults
    )
  }
}

// module apim './apimanagement.bicep' = {
//   dependsOn: [
//     privateDNS
//     hubglobal
//     hubSpokeSweden
//     hubSpokePoland
//   ]
//   scope: rgnetwork
//   name: 'apimanagement'
//   params: {
//     regionAndHubNetworkId : concat(
//       hubSpokePoland.outputs.regionAndHubNetworkId,
//       hubSpokeSweden.outputs.regionAndHubNetworkId
//     )
//   }
// }

// module privateDNS './privateDNS.bicep' = {
//   scope: rgnetwork
//   name: 'privateDNS'
//   params: {
//     networkIdsAndRegions: [
//       {
//         region: 'sweden'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/hub-swedencentral'
//       }
//       {
//         region: 'sweden'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/spoke-a-swedencentral'
//       }
//       {
//         region: 'sweden'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/spoke-b-swedencentral'
//       }
//       {
//         region: 'poland'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/hub-polandcentral'
//       }
//       {
//         region: 'poland'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/spoke-a-polandcentral'
//       }
//       {
//         region: 'poland'
//         networkid: '/subscriptions/d4114dca-ae03-432c-a4a0-b6398988b3c9/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/spoke-b-polandcentral'
//       }
//     ]
//     keyvaults: [
//       {
//         keyvaultName: 'kv-sweden-5zdakzxsmsnnc'
//         privateEndpointName: 'privateEndpoint-kv-sweden'
//       }
//       {
//         keyvaultName: 'kv-poland-pvk5ah5axffra'
//         privateEndpointName: 'privateEndpoint-kv-poland'
//       }
//     ]
//   }
// }
