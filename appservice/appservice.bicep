param resourceLocation string = 'swedencentral'
param regionName string = 'demo'

// App Service Plan
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-plan-${regionName}'
  params: {
    // Required parameters
    name: 'plan-${regionName}'
    // Non-required parameters
    kind: 'linux'
    location: resourceLocation
    skuCapacity: 1
    skuName: 'B1'
    tags: {
      Environment: 'Demo'
      Service: 'App Service'
      Purpose: 'Basic web app hosting'
    }
  }
}

// Web App (Linux)
module webApp 'br/public:avm/res/web/site:0.11.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-webapp-${regionName}'
  params: {
    // Required parameters
    kind: 'app,linux'
    name: 'webapp-${uniqueString(deployment().name, resourceLocation)}-${regionName}'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    // Non-required parameters
    location: resourceLocation
    httpsOnly: true
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: 'NODE|18-lts'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
    tags: {
      Environment: 'Demo'
      Service: 'Web App'
      Runtime: 'Node.js'
    }
  }
}

// Output the web app URL
output webAppUrl string = 'https://${webApp.outputs.defaultHostname}'
output webAppName string = webApp.outputs.name
output appServicePlanName string = appServicePlan.outputs.name