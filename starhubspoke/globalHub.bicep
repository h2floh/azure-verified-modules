param resourceLocation string = 'swedencentral'

param regionName string = 'global'

param globalPrivatAddressPrefix string = '10.0.0.0/8'

param addressPrefixHub string = '10.0.0.0/24' 
param addressPrefixHubBastion string = '10.0.0.0/26'
param addressPrefixHubFirewall string = '10.0.0.64/26'
param firewallIpAdress string = '10.0.0.68'
param addressPrefixHubFirewallManagement string = '10.0.0.128/26'

param polandAddressPrefix string = '10.4.0.0/14'
param polandFirewallIpAddress string = '10.4.0.68'
param swedenAddressPrefix string = '10.8.0.0/14'
param swedenFirewallIpAddress string = '10.8.0.68'

module hubroutes 'br/public:avm/res/network/route-table:0.2.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-udr-${regionName}-hub-route'
  params: {
    // Required parameters
    name: '${regionName}-hub-route'
    // Non-required parameters
    location: resourceLocation
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'FirewallDefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
      {
        name: 'ToPoland'
        properties: {
          addressPrefix: polandAddressPrefix
          nextHopIpAddress: polandFirewallIpAddress
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'ToSweden'
        properties: {
          addressPrefix: swedenAddressPrefix
          nextHopIpAddress: swedenFirewallIpAddress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module virtualHubNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-hub-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixHub
    ]
    name: 'hub-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixHubBastion
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: addressPrefixHubFirewall
        routeTableResourceId: hubroutes.outputs.resourceId
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: addressPrefixHubFirewallManagement
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

// module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
//   name: '${uniqueString(deployment().name, resourceLocation)}-globalBastion'
//   params: {
//     // Required parameters
//     name: 'globalBastion'
//     vNetId: virtualHubNetwork.outputs.resourceId
//     scaleUnits: 1 // testing reducing costs
//     skuName: 'Basic' // testing reducing costs
//   }
// }



module azfwmgmtip 'br/public:avm/res/network/public-ip-address:0.3.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Firewall'
  params: {
    // Required parameters
    name: 'pip-azfw-mgm-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.1.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-firewallPolicy-${regionName}'
  params: {
    // Required parameters
    name: 'firewallPolicy-${regionName}'
    // Non-required parameters
    location: resourceLocation
    tier: 'Basic'
    ruleCollectionGroups: [
      {
        name: 'rule-collection-group-${regionName}-hub-connectivity'
        priority: 5000
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: 'rule-collection-${regionName}-hub-connectivity'
            priority: 5555
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                destinationAddresses: [
                  globalPrivatAddressPrefix
                ]
                destinationFqdns: []
                destinationIpGroups: []
                destinationPorts: [
                  '*'
                ]
                ipProtocols: [
                  'TCP'
                  'UDP'
                  'ICMP'
                ]
                name: 'HubToHub'
                ruleType: 'NetworkRule'
                sourceAddresses: [
                  globalPrivatAddressPrefix
                ]
                sourceIpGroups: []
              }
            ]
          }
        ]
      }
    ]
  }
}


resource azfw 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  dependsOn: [
    azfwmgmtip
    virtualHubNetwork
    firewallPolicy
  ]
  name: '${regionName}Firewall'
  location: resourceLocation
  properties: {
    firewallPolicy: {
      id: firewallPolicy.outputs.resourceId
    }
    hubIPAddresses: {
      privateIPAddress: firewallIpAdress
    }
    ipConfigurations: [
      {
        id: 'internal'
        name: 'internal'
        properties: {
          subnet: {
            id: virtualHubNetwork.outputs.subnetResourceIds[1]
          }
        }
      }
    ]
    managementIpConfiguration: {
      id: 'external'
      name: 'external'
      properties: {
        publicIPAddress: {
          id: azfwmgmtip.outputs.resourceId
        }
        subnet: {
          id: virtualHubNetwork.outputs.subnetResourceIds[2]
        }
      }
    }
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
  }
}
