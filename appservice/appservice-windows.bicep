param resourceLocation string = 'swedencentral'
param regionName string = 'demo'

// App Service Plan (Windows)
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-winplan-${regionName}'
  params: {
    // Required parameters
    name: 'winplan-${regionName}'
    // Non-required parameters
    kind: 'windows'
    location: resourceLocation
    skuCapacity: 1
    skuName: 'B1'
    tags: {
      Environment: 'Demo'
      Service: 'App Service'
      Purpose: 'Basic web app hosting'
      OS: 'Windows'
    }
  }
}

// Web App (Windows/.NET)
module webApp 'br/public:avm/res/web/site:0.11.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-winwebapp-${regionName}'
  params: {
    // Required parameters
    kind: 'app'
    name: 'winwebapp-${uniqueString(deployment().name, resourceLocation)}-${regionName}'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    // Non-required parameters
    location: resourceLocation
    httpsOnly: true
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      alwaysOn: true
      netFrameworkVersion: 'v8.0'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
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
      Runtime: '.NET'
      OS: 'Windows'
    }
  }
}

// Output the web app URL
output webAppUrl string = 'https://${webApp.outputs.defaultHostname}'
output webAppName string = webApp.outputs.name
output appServicePlanName string = appServicePlan.outputs.name