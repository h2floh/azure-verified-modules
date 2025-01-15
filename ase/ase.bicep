param resourceLocation string = 'swedencentral'

param regionName string = 'global'

param globalPrivatAddressPrefix string = '10.0.0.0/8'
param addressPrefixBastion string = '10.0.0.128/29'
param addressPrefixHub string = '10.0.0.0/24' 
param addressPrefixApplicationGateway string = '10.0.0.192/26'
param applicationGatewayIpAdress string = '10.0.0.196'
param addressPrefixUser string = '10.0.0.136/29'
param adressPrefixASE string = '10.0.0.0/25'

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
        name: 'ASESubnet'
        addressPrefix: adressPrefixASE
        delegation: 'Microsoft.Web/hostingEnvironments'
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

module asEnvironment 'br/public:avm/res/web/hosting-environment:0.2.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-ase-${regionName}'
  params: {
    // Required parameters
    name: 'ase-${regionName}'
    subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
    // Non-required parameters
    clusterSettings: [
      {
        name: 'DisableTls1.0'
        value: '1'
      }
    ]
    internalLoadBalancingMode: 'Web, Publishing'
    kind: 'ASEv3'
    location: resourceLocation
    managedIdentities: {
      systemAssigned: true
    }
    networkConfiguration: {
      properties: {
        allowNewPrivateEndpointConnections: true
        ftpEnabled: true
        inboundIpAddressOverride: '10.0.0.10'
        remoteDebugEnabled: true
      }
    }
    tags: {
      hostingEnvironmentName: 'ase-${regionName}'
      resourceType: 'App Service Environment'
    }
    upgradePreference: 'Early'
    zoneRedundant: true
  }
}

module appplan1 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-appplan1-${regionName}'
  params: {
    // Required parameters
    name: 'windows-plan-a-${regionName}'
    // Non-required parameters
    kind: 'windows'
    location: resourceLocation
    appServiceEnvironmentId: asEnvironment.outputs.resourceId
    perSiteScaling: true
    skuCapacity: 1
    skuName: 'I1v2'
    tags: {
      Environment: 'App Plan 1'
      OS: 'Windows'
      Role: 'Various'
    }
    zoneRedundant: true
  }
}

module appplan2 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-appplan2-${regionName}'
  params: {
    // Required parameters
    name: 'linux-plan-a-${regionName}'
    // Non-required parameters
    kind: 'linux'
    location: resourceLocation
    appServiceEnvironmentId: asEnvironment.outputs.resourceId
    perSiteScaling: true
    skuCapacity: 1
    skuName: 'I1v2'
    tags: {
      Environment: 'App Plan 2'
      OS: 'Linux'
      Role: 'Various'
    }
    zoneRedundant: false
  }
}

module webapp1 'br/public:avm/res/web/site:0.11.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-webapp1-${regionName}'
  params: {
    // Required parameters
    kind: 'app'
    name: 'windows-inprocess'
    serverFarmResourceId: appplan1.outputs.resourceId
    // Non-required parameters
    basicPublishingCredentialsPolicies: [
      {
        allow: false
        name: 'ftp'
      }
      {
        allow: false
        name: 'scm'
      }
    ]
    httpsOnly: true
    location: resourceLocation
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccess: 'Disabled'
    scmSiteAlsoStopped: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'aspnetapp'
          value: 'samples/aspnetapp/aspnetapp'
        }
      ]
      sourceControl: {
        repoUrl: 'https://github.com/dotnet/dotnet-docker'
        branch: 'main'
        isManualIntegration: false
      }
    }
    slots: [
      {
        basicPublishingCredentialsPolicies: [
          {
            allow: false
            name: 'ftp'
          }
          {
            allow: false
            name: 'scm'
          }
        ]
        name: 'dev'
        siteConfig: {
          alwaysOn: true
          appSettings: [
            {
              name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
              value: 'true'
            }
            {
              name: 'aspnetapp'
              value: 'samples/aspnetapp/aspnetapp'
            }
          ]
          sourceControl: {
            repoUrl: 'https://github.com/dotnet/dotnet-docker'
            branch: 'main'
            isManualIntegration: false
          }
        }
      }
    ]
    vnetContentShareEnabled: true
    vnetImagePullEnabled: true
    vnetRouteAllEnabled: true
  }
}

module webapp2 'br/public:avm/res/web/site:0.11.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-webapp2-${regionName}'
  params: {
    // Required parameters
    kind: 'app,linux,container'
    name: 'linux-container'
    serverFarmResourceId: appplan2.outputs.resourceId
    // Non-required parameters
    basicPublishingCredentialsPolicies: [
      {
        allow: false
        name: 'ftp'
      }
      {
        allow: false
        name: 'scm'
      }
    ]
    httpsOnly: true
    location: resourceLocation
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccess: 'Disabled'
    scmSiteAlsoStopped: true
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/dotnet/samples:aspnetapp'
    }
    slots: [
      {
        basicPublishingCredentialsPolicies: [
          {
            name: 'ftp'
          }
          {
            name: 'scm'
          }
        ]
        name: 'dev'
        siteConfig: {
          alwaysOn: true
          linuxFxVersion: 'DOCKER|mcr.microsoft.com/dotnet/samples:aspnetapp'
        }
      }
    ]
    vnetContentShareEnabled: true
    vnetImagePullEnabled: true
    vnetRouteAllEnabled: true
  }
}

module virtualMachineA 'br/public:avm/res/compute/virtual-machine:0.1.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-${regionName}-vm-a'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'windows-11'
      sku: 'win11-24h2-pro'
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
      diskSizeGB: '256'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_D2s_v3'
    // encryptionAtHost: true // default true if not working use 'az feature register --name EncryptionAtHost --namespace Microsoft.Compute'
    // Non-required parameters
    adminPassword: 'Password1234!'
  }
}

module privateDnsZoneBlob 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-dns-zone-${regionName}'
  params: {
    // Required parameters
    name: '${asEnvironment.outputs.name}.appserviceenvironment.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
        registrationEnabled: false
      } 
    ]
    a: [
      {
        name: '*'
        ttl: 300
        aRecords: [
          {
            ipv4Address: '10.0.0.4'
          }
        ]
      }
      {
        name: '@'
        ttl: 300
        aRecords: [
          {
            ipv4Address: '10.0.0.4'
          }
        ]
      }
      {
        name: '*.scm'
        ttl: 300
        aRecords: [
          {
            ipv4Address: '10.0.0.4'
          }
        ]
      }
    ]
  }
}
