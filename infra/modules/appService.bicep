param appServicePlanName string
param webAppName string
param location string
param sku string
param acrLoginServer string
param containerImage string
param appInsightsConnectionString string

var skuNormalized = toLower(sku)
var skuTier = contains(skuNormalized, 'v3')
  ? 'PremiumV3'
  : contains(skuNormalized, 'v2')
    ? 'PremiumV2'
    : startsWith(skuNormalized, 'p')
      ? 'Premium'
      : startsWith(skuNormalized, 's')
        ? 'Standard'
        : startsWith(skuNormalized, 'f')
          ? 'Free'
          : 'Basic'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: skuTier
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImage}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

output webAppName string = webApp.name
output principalId string = webApp.identity.principalId
