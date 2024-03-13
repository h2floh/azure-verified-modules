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

param addressPrefixSpokeA string = '10.8.16.0/20'
param addressPrefixSpokeASubnetA string = '10.8.16.0/24'
param addressPrefixSpokeASubnetB string = '10.8.17.0/24'

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
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: globalPrivatAddressPrefix
          nextHopIpAddress: globalFirewallAddress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

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
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: addressPrefixHubFirewallManagement
        routeTableResourceId: hubroutes.outputs.resourceId
      }
    ]
  }
}

output virtualHubNetworkId string = virtualHubNetwork.outputs.resourceId

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
  }
}

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.1.2' = {
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
              {
                destinationAddresses: [
                  addressPrefixSpokeA
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
                name: 'SpokeBtoA'
                ruleType: 'NetworkRule'
                sourceAddresses: [
                  addressPrefixSpokeB
                ]
                sourceIpGroups: []
              }
              {
                destinationAddresses: [
                  addressPrefixSpokeB
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
                name: 'SpokeAtoB'
                ruleType: 'NetworkRule'
                sourceAddresses: [
                  addressPrefixSpokeA
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
          addressPrefix: addressPrefixSpokeB
          nextHopIpAddress: firewallIpAdress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module spokea 'br/public:avm/res/network/virtual-network:0.1.1' = {
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
      }
      {
        name: 'subnet-b'
        addressPrefix: addressPrefixSpokeASubnetB
        routeTableResourceId: spokearoutes.outputs.resourceId
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
          addressPrefix: addressPrefixSpokeA
          nextHopIpAddress: firewallIpAdress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module spokeb 'br/public:avm/res/network/virtual-network:0.1.1' = {
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
      }
      {
        name: 'subnet-b'
        addressPrefix: addressPrefixSpokeBSubnetB
        routeTableResourceId: spokebroutes.outputs.resourceId
      }
    ]
  }
}



module virtualMachineA 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
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
        keyData: 'ssh-rsa ***REMOVED***'
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}

module virtualMachineB 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
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
        keyData: 'ssh-rsa ***REMOVED***'
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
  }
}
