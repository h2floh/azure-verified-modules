param resourceLocation string = 'italynorth'

param regionName string = 'global'

param globalPrivatAddressPrefix string = '10.0.0.0/8'
param addressPrefixBastion string = '10.0.0.128/29'
param addressPrefixHub string = '10.0.0.0/24' 
param addressPrefixApplicationGateway string = '10.0.0.192/26'
param applicationGatewayIpAdress string = '10.0.0.196'
param addressPrefixUser string = '10.0.0.136/29'
param peeringNetworkId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avm-az-00000000/providers/Microsoft.Network/virtualNetworks/vnet-avm-az-00000000'
param adressPrefixPrivateLink string = '10.0.0.0/25'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-network-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefixHub
    ]
    name: 'vnet-${regionName}'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'ApplicationGatewaySubnet'
        addressPrefix: addressPrefixApplicationGateway
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: adressPrefixPrivateLink
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixBastion
        // No route table can be attached
      }
      {
        name: 'UserSubnet'
        addressPrefix: addressPrefixUser
        // No route table can be attached
      }
    ]
    peerings: [
      {
        remoteVirtualNetworkResourceId: peeringNetworkId
        remotePeeringEnabled: true
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}Bastion'
  params: {
    // Required parameters
    name: '${regionName}Bastion'
    vNetId: virtualNetwork.outputs.resourceId
    scaleUnits: 1 // testing reducing costs
    skuName: 'Basic' // testing reducing costs
    location: resourceLocation
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
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[3]
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
        keyData: loadTextContent('../id_rsa.pub')
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
    managedIdentities: {
        systemAssigned: false
        userAssignedResourceIds: [userAssignedIdentity.outputs.resourceId]
    }
  }
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-umsi'
  params: {
    // Required parameters
    name: '${regionName}-umsi'
    // Non-required parameters
    federatedIdentityCredentials: [
      {
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://token.actions.githubusercontent.com'
        name: 'GitHubWorkflowDefault'
        subject: 'repo:flowsoft-org/azure-verified-modules:ref:refs/heads/main'
      }
      {
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://token.actions.githubusercontent.com'
        name: 'GitHubWorkflowTest'
        subject: 'repo:flowsoft-org/azure-verified-modules:ref:refs/heads/h2floh/managed-connected-runners-demo'
      }
    ]
    location: resourceLocation
  }
}

module vault 'br/public:avm/res/key-vault/vault:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-kv-${regionName}'
  params: {
    // Required parameters
    name: 'kv-${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    enablePurgeProtection: false
    sku: 'standard'
    location: resourceLocation
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
  }
}

module kvmsiRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-kvrole-${regionName}'
  params: {
    // Required parameters
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: vault.outputs.resourceId
    roleDefinitionId: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // 'Key Vault Secrets Officer'
    // Non-required parameters
    description: 'Role assignment for the user assigned identity'
    principalType: 'ServicePrincipal'
  }
}

module privateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-pekv-${regionName}'
  params: {
    // Required parameters
    name: 'privateEndpoint-kv-${regionName}'
    subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
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

output networkIdsAndRegions array = [
  {
    networkid: virtualNetwork.outputs.resourceId
    region: regionName
  }
]
