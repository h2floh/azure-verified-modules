param resourceLocation string = 'swedencentral'
param sapConnectionString string = ''
param sqlServerAdminLogin string = 'sqladmin'
@secure()
param sqlServerAdminPassword string

// Generate unique names for resources
var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = 'st${uniqueSuffix}'
var logicAppName = 'logic-sap-sql-${uniqueSuffix}'
var sqlServerName = 'sql-${uniqueSuffix}'
var sqlDatabaseName = 'db-sap-data'
var servicePlanName = 'asp-${uniqueSuffix}'

// Storage Account for Logic App Standard
module storageAccount 'br/public:avm/res/storage/storage-account:0.6.7' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-storage'
  params: {
    // Required parameters
    name: storageAccountName
    // Non-required parameters
    location: resourceLocation
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// App Service Plan for Logic App Standard
module servicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-serverfarm'
  params: {
    // Required parameters
    name: servicePlanName
    // Non-required parameters
    location: resourceLocation
    skuName: 'WS1'
    skuTier: 'WorkflowStandard'
    kind: 'elastic'
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 20
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: resourceLocation
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// SQL Server Firewall Rule to allow Azure services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: resourceLocation
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

// Logic App Standard
module logicApp 'br/public:avm/res/web/site:0.11.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-logicapp'
  params: {
    // Required parameters
    kind: 'functionapp,workflowapp'
    name: logicAppName
    serverFarmResourceId: servicePlan.outputs.resourceId
    // Non-required parameters
    location: resourceLocation
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.outputs.name};AccountKey=${storageAccount.outputs.primaryAccessKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.outputs.name};AccountKey=${storageAccount.outputs.primaryAccessKey};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'SAP_CONNECTION_STRING'
          value: sapConnectionString
        }
        {
          name: 'SQL_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlServerAdminLogin};Password=${sqlServerAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
}

// Outputs
output logicAppName string = logicApp.outputs.name
output logicAppId string = logicApp.outputs.resourceId
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output storageAccountName string = storageAccount.outputs.name