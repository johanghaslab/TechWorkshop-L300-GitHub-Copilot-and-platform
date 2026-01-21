// App Service Plan + Web App (Linux, Docker)
param location string
param app string
param env string
param acrLoginServer string
param managedIdentityId string
param imageName string
param imageTag string
param appInsightsKey string

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${app}-${env}'
  location: location
  sku: {
    name: 'P0V3'
    tier: 'PremiumV3'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${app}-${env}'
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': 'web'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsKey
        }
      ]
    }
  }
}
