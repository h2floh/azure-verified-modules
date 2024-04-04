param resourceLocation string = 'swedencentral'

param regionName string = 'global'

param globalPrivatAddressPrefix string = '10.0.0.0/8'

param addressPrefixHub string = '10.0.0.0/24' 
param addressPrefixHubBastion string = '10.0.0.0/26'
param addressPrefixHubFirewall string = '10.0.0.64/26'
param firewallIpAdress string = '10.0.0.68'
param addressPrefixHubFirewallManagement string = '10.0.0.128/26'
param addressPrefixApplicationGateway string = '10.0.0.192/26'
param applicationGatewayIpAdress string = '10.0.0.196'

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
      {
        name: 'ToRegion'
        properties: {
          addressPrefix: addressPrefixHub
          nextHopType: 'VnetLocal'
        }
      }
    ]
  }
}

module appgwroutes 'br/public:avm/res/network/route-table:0.2.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-udr-${regionName}-appgw-route'
  params: {
    // Required parameters
    name: '${regionName}-appgw-route'
    // Non-required parameters
    location: resourceLocation
    disableBgpRoutePropagation: true
    routes: [
      // For routes associated to subnet containing Application Gateway V2, please ensure '0.0.0.0/0' uses NextHopType as 'Internet'
      {
        name: 'Internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
      {
        name: 'FirewallDefaultRoute'
        properties: {
          addressPrefix: '10.0.0.0/8'
          nextHopIpAddress: firewallIpAdress
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
        // No route table can be attached
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
      {
        name: 'ApplicationGatewaySubnet'
        addressPrefix: addressPrefixApplicationGateway
        routeTableResourceId: hubroutes.outputs.resourceId
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

output networkIdsAndRegions array = [
  {
    networkid: virtualHubNetwork.outputs.resourceId
    region: regionName
  }
]

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
    zones: [
      '1'
      '2'
      '3'
    ]
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
  // SLA 99.99 doesn't add additional costs except traffic between zones
  zones: [
    '1'
    '2'
    '3'
  ]
}

module appgwip 'br/public:avm/res/network/public-ip-address:0.3.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}AppGateway'
  params: {
    // Required parameters
    name: 'pip-app-gw-${regionName}'
    // Non-required parameters
    location: resourceLocation
    zones: [
      '1'
      '2'
      '3'
    ]
  }
}

var applicationGateWayName = 'app-gateway-${regionName}'
resource appGateway 'Microsoft.Network/applicationGateways@2023-04-01' = {
  name: applicationGateWayName
  location: resourceLocation
  properties: {
    // does not support Autoscaling for the selected SKU tier Basic. Supported SKU tiers are Standard_v2,WAF_v2.
    autoscaleConfiguration: {
      maxCapacity: 2
      minCapacity: 1
    }
    backendHttpSettingsCollection: [
      {
        name: 'HTTPsetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
      {
        name: 'HTTPSsetting'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    backendAddressPools: [
      {
        id: 'polandvm'
        name: 'polandvmpool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'poland-vm-a.poland.internal.flow-soft.com'
            }
            {
              fqdn: 'poland-vm-b.poland.internal.flow-soft.com'
            }
          ]
        }
      }
      {
        id: 'swedenvm'
        name: 'swedenvmpool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'sweden-vm-a.sweden.internal.flow-soft.com'
            }
            {
              fqdn: 'sweden-vm-b.sweden.internal.flow-soft.com'
            }
          ]
        }
      }
      {
        id: 'ci'
        name: 'cipool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'ci-sweden.sweden.internal.flow-soft.com'
            }
            {
              fqdn: 'ci-poland.poland.internal.flow-soft.com'
            }
          ]
        }
      }
    ]
    frontendIPConfigurations: [
      {
        id: 'internalFE'
        name: 'internalFE'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: applicationGatewayIpAdress
          subnet: {
            id: virtualHubNetwork.outputs.subnetResourceIds[3]
          }
        }
      }
      {
        id: 'externalFE'
        name: 'externalFE'
        properties: {
          publicIPAddress: {
            id: appgwip.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        id: 'http'
        name: 'http'
        properties: {
          port: 80
        }
      }
      {
        id: 'https'
        name: 'https'
        properties: {
          port: 443
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        id: 'internalBE'
        name: 'internalBE'
        properties: {
          subnet: {
            id: virtualHubNetwork.outputs.subnetResourceIds[3]
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'ListenerInternal'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'internalFE')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'http')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'ListenerExternal'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'externalFE')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'http')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'RoutingRuleInternal'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'ListenerInternal')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'polandvmpool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'HTTPsetting')
          }
        }
      }
      {
        name: 'RoutingRuleExternal'
        properties: {
          ruleType: 'Basic'
          priority: 2
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'ListenerExternal')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'polandvmpool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'HTTPsetting')
          }
        }
      }
    ]
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}
