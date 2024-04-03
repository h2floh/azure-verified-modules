param resourceLocation string = 'swedencentral'

param peeringNetworks array = []

param regionName string = 'sweden'

param globalPrivatAddressPrefix string = '10.0.0.0/8'
param globalFirewallAddress string = '10.0.0.68'

param addressPrefixHub string = '10.8.0.0/24' 
param addressPrefixHubBastion string = '10.8.0.0/26'
param addressPrefixHubFirewall string = '10.8.0.64/26'
param firewallIpAdress string = '10.8.0.68'
param addressPrefixHubFirewallManagement string = '10.8.0.128/26'
param addressPrefixAPIManagement string = '10.8.0.192/26'

param addressPrefixSpokeA string = '10.8.16.0/20'
param addressPrefixSpokeASubnetA string = '10.8.16.0/24'
param addressPrefixSpokeASubnetB string = '10.8.17.0/24'
param addressPrefixSpokeASubnetC string = '10.8.18.0/24'

param addressPrefixSpokeB string = '10.8.32.0/20'
param addressPrefixSpokeBSubnetA string = '10.8.33.0/24'
param addressPrefixSpokeBSubnetB string = '10.8.34.0/24'

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
        name: 'Global'
        properties: {
          addressPrefix: globalPrivatAddressPrefix
          nextHopIpAddress: globalFirewallAddress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

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

module apimPIP 'br/public:avm/res/network/public-ip-address:0.3.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-pip-apim-${regionName}'
  params: {
    // Required parameters
    name: 'pip-apim-${regionName}'
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

resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: 'nat-${regionName}'
  location: resourceLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natGatewayPIP.outputs.resourceId
      }
    ]
  }
}

// module natGateway 'br/public:avm/res/network/nat-gateway:1.0.4' = {
//   dependsOn: [
//     natGatewayPIP
//   ]
//   name: '${uniqueString(deployment().name, resourceLocation)}-nat-${regionName}'
//   params: {
//     // Required parameters
//     name: 'nat-${regionName}'
//     // Non-required parameters
//     location: resourceLocation
//     publicIpResourceIds: [
//       natGatewayPIP.outputs.resourceId
//     ]
//   }
// }

module virtualHubNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-hub-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixHub
    ]
    name: 'hub-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      for peeringNetwork in peeringNetworks: {
        remoteVirtualNetworkId: peeringNetwork.remoteVirtualNetworkId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixHubBastion
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: addressPrefixHubFirewall
        routeTableResourceId: hubroutes.outputs.resourceId
        natGatewayResourceId: natGateway.id
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: addressPrefixHubFirewallManagement
      }
      {
        name: 'APIManagement'
        addressPrefix: addressPrefixAPIManagement
        routeTableResourceId: hubroutes.outputs.resourceId
        delegations: [
          {
            name: 'APIManagement'
            properties: {
              serviceName: 'Microsoft.ApiManagement/service'
            }
          }
        ]
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId
output regionAndHubNetworkId array = [
  {
    region: regionName
    location: resourceLocation
    subnetid: virtualHubNetwork.outputs.subnetResourceIds[3]
    publicIpId: apimPIP.outputs.resourceId
  }
]

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Bastion'
  params: {
    // Required parameters
    name: '${regionName}Bastion'
    vNetId: virtualHubNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
  }
}

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
  dependsOn: [
    virtualHubNetwork
    spokea
    spokeb
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-firewallPolicy-${regionName}'
  params: {
    // Required parameters
    name: 'firewallPolicy-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    tier: 'Basic'
    ruleCollectionGroups: [
      {
        name: 'rule-collection-group-${regionName}-spoke-connectivity'
        priority: 5000
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: 'rule-collection-${regionName}-spoke-connectivity'
            priority: 5555
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              // {
              //   destinationAddresses: [
              //     addressPrefixSpokeA
              //   ]
              //   destinationFqdns: []
              //   destinationIpGroups: []
              //   destinationPorts: [
              //     '*'
              //   ]
              //   ipProtocols: [
              //     'TCP'
              //     'UDP'
              //     'ICMP'
              //   ]
              //   name: 'SpokeBtoA'
              //   ruleType: 'NetworkRule'
              //   sourceAddresses: [
              //     addressPrefixSpokeB
              //   ]
              //   sourceIpGroups: []
              // }
              // {
              //   destinationAddresses: [
              //     addressPrefixSpokeB
              //   ]
              //   destinationFqdns: []
              //   destinationIpGroups: []
              //   destinationPorts: [
              //     '*'
              //   ]
              //   ipProtocols: [
              //     'TCP'
              //     'UDP'
              //     'ICMP'
              //   ]
              //   name: 'SpokeAtoB'
              //   ruleType: 'NetworkRule'
              //   sourceAddresses: [
              //     addressPrefixSpokeA
              //   ]
              //   sourceIpGroups: []
              // }
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
              {
                destinationAddresses: [
                  '*'
                ]
                destinationFqdns: []
                destinationIpGroups: []
                destinationPorts: [
                  '80'
                  '443'
                ]
                ipProtocols: [
                  'TCP'
                ]
                name: 'ToInternet'
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
    bastionHost
    firewallPolicy
    natGatewayPIP
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

module spokearoutes 'br/public:avm/res/network/route-table:0.2.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-udr-${regionName}-spokea-route'
  params: {
    // Required parameters
    name: '${regionName}-spokea-route'
    // Non-required parameters
    location: resourceLocation
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallIpAdress
          nextHopType: 'VirtualAppliance'
        }
      }
      // {
      //   name: 'default'
      //   properties: {
      //     addressPrefix: addressPrefixSpokeB
      //     nextHopIpAddress: firewallIpAdress
      //     nextHopType: 'VirtualAppliance'
      //   }
      // }
      // {
      //   name: 'Global'
      //   properties: {
      //     addressPrefix: globalPrivatAddressPrefix
      //     nextHopIpAddress: firewallIpAdress
      //     nextHopType: 'VirtualAppliance'
      //   }
      // }
    ]
  }
}

module networkSecurityGroupSpokeASubnetA 'br/public:avm/res/network/network-security-group:0.1.3' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-spokea-subneta-nsg'
  params: {
    // Required parameters
    name: 'nsg-spokea-subneta-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}

module networkSecurityGroupSpokeASubnetB 'br/public:avm/res/network/network-security-group:0.1.3' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-spokea-subnetb-nsg'
  params: {
    // Required parameters
    name: 'nsg-spokea-subnetb-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}

module networkSecurityGroupSpokeASubnetC 'br/public:avm/res/network/network-security-group:0.1.3' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-spokea-subnetc-nsg'
  params: {
    // Required parameters
    name: 'nsg-spokea-subnetc-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}

module spokea 'br/public:avm/res/network/virtual-network:0.1.1' = {
  dependsOn: [
    virtualHubNetwork
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-a-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixSpokeA
    ]
    name: 'spoke-a-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      {
        remoteVirtualNetworkId: virtualHubNetwork.outputs.resourceId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'subnet-a'
        addressPrefix: addressPrefixSpokeASubnetA
        routeTableResourceId: spokearoutes.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupSpokeASubnetA.outputs.resourceId
      }
      {
        name: 'subnet-b'
        addressPrefix: addressPrefixSpokeASubnetB
        routeTableResourceId: spokearoutes.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupSpokeASubnetB.outputs.resourceId
      }
      {
        name: 'subnet-c'
        addressPrefix: addressPrefixSpokeASubnetC
        routeTableResourceId: spokearoutes.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupSpokeASubnetC.outputs.resourceId
        delegations: [
          {
            name: 'ContainerInstances'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
      }
    ]
  }
}

module spokebroutes 'br/public:avm/res/network/route-table:0.2.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-udr-sweden-spokeb-route'
  params: {
    // Required parameters
    name: '${regionName}-spokeb-route'
    // Non-required parameters
    location: resourceLocation
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallIpAdress
          nextHopType: 'VirtualAppliance'
        }
      }
      // {
      //   name: 'default'
      //   properties: {
      //     addressPrefix: addressPrefixSpokeA
      //     nextHopIpAddress: firewallIpAdress
      //     nextHopType: 'VirtualAppliance'
      //   }
      // }
      // {
      //   name: 'Global'
      //   properties: {
      //     addressPrefix: globalPrivatAddressPrefix
      //     nextHopIpAddress: firewallIpAdress
      //     nextHopType: 'VirtualAppliance'
      //   }
      // }
    ]
  }
}

module networkSecurityGroupSpokeBSubnetA 'br/public:avm/res/network/network-security-group:0.1.3' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-spokeb-subneta-nsg'
  params: {
    // Required parameters
    name: 'nsg-spokeb-subneta-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}

module networkSecurityGroupSpokeBSubnetB 'br/public:avm/res/network/network-security-group:0.1.3' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-spokeb-subnetb-nsg'
  params: {
    // Required parameters
    name: 'nsg-spokeb-subnetb-${regionName}'
    // Non-required parameters
    location: resourceLocation
  }
}


module spokeb 'br/public:avm/res/network/virtual-network:0.1.1' = {
  dependsOn: [
    spokea
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-spoke-b-${resourceLocation}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixSpokeB
    ]
    name: 'spoke-b-${resourceLocation}'
    // Non-required parameters
    location: resourceLocation
    peerings: [
      {
        remoteVirtualNetworkId: virtualHubNetwork.outputs.resourceId
        remotePeeringEnabled: true
      }
    ]
    subnets: [
      {
        name: 'subnet-a'
        addressPrefix: addressPrefixSpokeBSubnetA
        routeTableResourceId: spokebroutes.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupSpokeBSubnetA.outputs.resourceId
      }
      {
        name: 'subnet-b'
        addressPrefix: addressPrefixSpokeBSubnetB
        routeTableResourceId: spokebroutes.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupSpokeBSubnetB.outputs.resourceId
      }
    ]
  }
}



module virtualMachineA 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  dependsOn: [
    spokea
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm-a'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: '${regionName}-vm-a'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: spokea.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
        enablePublicIP: false
        enableAcceleratedNetworking: false // Accelerated Networking is not supported for B1s
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '32'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B1s'
    // encryptionAtHost: true // default true if not working use 'az feature register --name EncryptionAtHost --namespace Microsoft.Compute'
    // Non-required parameters
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbayTrbSOQE+jlz+PzfJQzIHgATX2Gj+owdpD1/HHqtDrXMd6SqNlyf3/k0pYbCsXjA/A7MzJgAT1Kj5GwjGlDkIQA8kjVW9TByPDV+s//C6vTy1H6dE4jZYvTeolsm7JBkGOyTXI+pcL6vLkhzWIESxkeUG/LR08UPWVjcfk2Oqsk2I/AUiZxWhWcVIYasfJSHolrOHPcRdLNQoAY7iw3vrq4kw6DkcTVa9BTdxt0sym/j6TPMAJgA1z53ONt38PywIZ/Fb/dQer5QusOSJS4+rKR9gYHOAio3TWnmG7azERXpD2btD4OV4jvFhDx2EuFhRC4ZYLaPX5dnd4FIM2yhFi/zFWoCpYOSIZt21DMYr4qTZWP0arf/IL23ZkxssQlNTKlYdANfc1R0r7JMJO36/xZZq1h8N80MHKMyWWuXOYfGksrh617jqysOY20F09f0HpdES3oWN4vpRCWSAmDLyLnljg0Z20NTrKxDcCcAXj3vcZzxB+9UPnAQlfeX9c='
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

module virtualMachineB 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  dependsOn: [
    spokeb
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm-b'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: '${regionName}-vm-b'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: spokeb.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
        enablePublicIP: false
        enableAcceleratedNetworking: false // Accelerated Networking is not supported for B1s
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '32'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B1s'
    // encryptionAtHost: true // default true if not working use 'az feature register --name EncryptionAtHost --namespace Microsoft.Compute'
    // Non-required parameters
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbayTrbSOQE+jlz+PzfJQzIHgATX2Gj+owdpD1/HHqtDrXMd6SqNlyf3/k0pYbCsXjA/A7MzJgAT1Kj5GwjGlDkIQA8kjVW9TByPDV+s//C6vTy1H6dE4jZYvTeolsm7JBkGOyTXI+pcL6vLkhzWIESxkeUG/LR08UPWVjcfk2Oqsk2I/AUiZxWhWcVIYasfJSHolrOHPcRdLNQoAY7iw3vrq4kw6DkcTVa9BTdxt0sym/j6TPMAJgA1z53ONt38PywIZ/Fb/dQer5QusOSJS4+rKR9gYHOAio3TWnmG7azERXpD2btD4OV4jvFhDx2EuFhRC4ZYLaPX5dnd4FIM2yhFi/zFWoCpYOSIZt21DMYr4qTZWP0arf/IL23ZkxssQlNTKlYdANfc1R0r7JMJO36/xZZq1h8N80MHKMyWWuXOYfGksrh617jqysOY20F09f0HpdES3oWN4vpRCWSAmDLyLnljg0Z20NTrKxDcCcAXj3vcZzxB+9UPnAQlfeX9c='
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

output networkIdsAndRegions array = [
  {
    networkid: virtualHubNetwork.outputs.resourceId
    region: regionName
  }
  {
    networkid: spokea.outputs.resourceId
    region: regionName
  }
  {
    networkid: spokeb.outputs.resourceId
    region: regionName
  }
]

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  dependsOn: [
    spokea
  ]
  name: 'ci-${regionName}'
  location: resourceLocation
  properties: {
    containers: [
      {
        name: 'webapp${regionName}'
        properties: {
          // environmentVariables: [
          //   {
          //     name: 'string'
          //     secureValue: 'string'
          //     //value: 'string'
          //   }
          // ]
          image: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
          ports: [
            {
              port: 8080
              protocol: 'TCP'
            }
          ]
          resources: {
            limits: {
              cpu: 1
              memoryInGB: json('0.5')
            }
            requests: {
              cpu: 1
              memoryInGB: json('0.5')
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Private'
      ports: [
        {
          port: 8080
          protocol: 'TCP'
        }
      ]
    }
    osType: 'Linux'
    restartPolicy: 'Always'
    sku: 'Standard'
    subnetIds: [
      {
        id: spokea.outputs.subnetResourceIds[2]
        name: 'SpokeA Container Subnet'
      }
    ]
  }
}

module vault 'br/public:avm/res/key-vault/vault:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-kv-${regionName}'
  params: {
    // Required parameters
    name: 'kv-${regionName}-${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    enablePurgeProtection: false
    location: resourceLocation
  }
}

module privateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.0' = {
  dependsOn: [
    vault
  ]
  name: '${uniqueString(deployment().name, resourceLocation)}-pekv-${regionName}'
  params: {
    // Required parameters
    name: 'privateEndpoint-kv-${regionName}'
    subnetResourceId: spokeb.outputs.subnetResourceIds[1]
    // Non-required parameters
    location: resourceLocation
    lock: {}
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: 'pekv-${regionName}'
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: vault.outputs.resourceId
        }
      }
    ]
  }
}

output keyvaults array = [
  {
    keyvaultName: vault.outputs.name
    privateEndpointName: privateEndpoint.outputs.name
  }
]

