param resourceLocation string = 'swedencentral'
param regionName string = 'global'
param addressPrefix string = '10.0.0.0/16'
param addressPrefixAks string = '10.0.1.0/24'
param addressPrefixBastion string = '10.0.0.0/26'
param addressPrefixVM string = '10.0.0.64/26'
param addressPrefixPrivateEndpoints string = '10.0.0.128/26'

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-network-${regionName}'
  params: {
    // Required parameters
    addressPrefixes: [
      addressPrefix
    ]
    name: 'vnet-${regionName}-aks'
    // Non-required parameters
    location: resourceLocation
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: addressPrefixBastion
        // No route table can be attached
      }
      {
        name: 'VMSubnet'
        addressPrefix: addressPrefixVM
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: addressPrefixPrivateEndpoints
      }
      {
        name: 'AksSubnet'
        addressPrefix: addressPrefixAks
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

module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-identity'
  params: {
    // Required parameters
    name: 'aks-${regionName}-identity'
    // Non-required parameters
    location: resourceLocation
  }
}

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-aks'
  params: {
    // Required parameters
    name: 'aks-${regionName}'
    primaryAgentPoolProfile: [
      {
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        count: 3
        enableAutoScaling: true
        maxCount: 5
        maxPods: 30
        minCount: 1
        mode: 'System'
        name: 'systempool'
        nodeLabels: {}
        nodeTaints: []
        osDiskSizeGB: 128
        osType: 'Linux'

        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D2s_v3'
        vnetSubnetID: virtualNetwork.outputs.subnetResourceIds[3]
      }
    ]
    // Non-required parameters
    location: resourceLocation
    managedIdentities: {
      userAssigned: {
        '${managedIdentity.outputs.resourceId}': {}
      }
    }
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    serviceCidr: '172.16.0.0/16'
    dnsServiceIP: '172.16.0.10'
    outboundType: 'loadBalancer'
    skuTier: 'Free'
    enableRBAC: true
    aadProfileManaged: true
    aadProfileEnableAzureRBAC: true
    autoUpgradeProfileUpgradeChannel: 'stable'
    disableLocalAccounts: true
    enablePodSecurityPolicy: false
    enablePrivateCluster: false
    enableStorageProfileDiskCSIDriver: true
    enableStorageProfileFileCSIDriver: true
    enableStorageProfileSnapshotController: true
    kubernetesVersion: '1.28.5'
    loadBalancerSku: 'standard'
    monitoringWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    enableOmsAgent: true
    tags: {
      Environment: 'Demo'
      Service: 'AKS'
      Region: regionName
    }
  }
}

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.3.4' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-law'
  params: {
    // Required parameters
    name: 'law-${regionName}-aks'
    // Non-required parameters
    location: resourceLocation
    retentionInDays: 30
    skuName: 'PerGB2018'
    tags: {
      Environment: 'Demo'
      Service: 'LogAnalytics'
      Region: regionName
    }
  }
}

module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-acr'
  params: {
    // Required parameters
    name: 'acr${toLower(regionName)}${uniqueString(deployment().name, resourceLocation)}'
    // Non-required parameters
    location: resourceLocation
    acrSku: 'Basic'
    tags: {
      Environment: 'Demo'
      Service: 'ContainerRegistry'
      Region: regionName
    }
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: '${regionName}-vm'
    location: resourceLocation
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
        enablePublicIP: false
        enableAcceleratedNetworking: false
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: '64'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B2s'
    // Non-required parameters
    disablePasswordAuthentication: true
    publicKeys: [
      {
        keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...' // Replace with your actual public key
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
    tags: {
      Environment: 'Demo'
      Service: 'ManagementVM'
      Region: regionName
    }
  }
}

// Output important information
output aksClusterName string = aksCluster.outputs.name
output aksClusterResourceId string = aksCluster.outputs.resourceId
output containerRegistryName string = containerRegistry.outputs.name
output virtualNetworkName string = virtualNetwork.outputs.name
output managedIdentityResourceId string = managedIdentity.outputs.resourceId