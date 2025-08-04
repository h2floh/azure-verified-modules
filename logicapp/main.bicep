targetScope = 'subscription'

param resourceLocation string = 'swedencentral'
param sapConnectionString string = ''
param sqlServerAdminLogin string = 'sqladmin'
@secure()
param sqlServerAdminPassword string

resource rgLogicApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-logicapp-sap-sql'
  location: resourceLocation
}

module logicAppResources './logicapp.bicep' = {
  scope: rgLogicApp
  name: 'logicapp-sap-sql'
  params: {
    resourceLocation: resourceLocation
    sapConnectionString: sapConnectionString
    sqlServerAdminLogin: sqlServerAdminLogin
    sqlServerAdminPassword: sqlServerAdminPassword
  }
}