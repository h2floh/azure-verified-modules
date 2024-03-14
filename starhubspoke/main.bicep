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
    addressPrefixHub: '10.8.0.0/24'
    addressPrefixHubBastion: '10.8.0.0/26'
    addressPrefixHubFirewall: '10.8.0.64/26'
    firewallIpAdress: '10.8.0.68'
    addressPrefixHubFirewallManagement: '10.8.0.128/26'
    addressPrefixSpokeA: '10.8.16.0/20'
    addressPrefixSpokeASubnetA: '10.8.16.0/24'
    addressPrefixSpokeASubnetB: '10.8.17.0/24'
    addressPrefixSpokeB: '10.8.32.0/20'
    addressPrefixSpokeBSubnetA: '10.8.33.0/24'
    addressPrefixSpokeBSubnetB: '10.8.34.0/24'
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}

module hubSpokePoland './hubSpoke.bicep' = {
  scope: rgnetwork
  name: 'hubPoland'
  params: {
    // 10.4.0.0/14 for whole region
    resourceLocation: 'polandcentral'
    regionName: 'poland'
    globalPrivatAddressPrefix: '10.0.0.0/8'
    globalFirewallAddress: '10.0.0.68'
    addressPrefixHub: '10.4.0.0/24'
    addressPrefixHubBastion: '10.4.0.0/26'
    addressPrefixHubFirewall: '10.4.0.64/26'
    firewallIpAdress: '10.4.0.68'
    addressPrefixHubFirewallManagement: '10.4.0.128/26'
    addressPrefixSpokeA: '10.4.16.0/20'
    addressPrefixSpokeASubnetA: '10.4.16.0/24'
    addressPrefixSpokeASubnetB: '10.4.17.0/24'
    addressPrefixSpokeB: '10.4.32.0/20'
    addressPrefixSpokeBSubnetA: '10.4.33.0/24'
    addressPrefixSpokeBSubnetB: '10.4.34.0/24'
    peeringNetworks: [{
      remoteVirtualNetworkId: hubglobal.outputs.virtualHubNetworkId
    }]
  }
}
