targetScope = 'resourceGroup'

param location string = 'swedencentral'
param environmentName string = 'dev'
param resourcePrefix string = 'zava'
param appServiceSku string = 'B1'
param acrSku string = 'Basic'

var nameSuffix = uniqueString(resourceGroup().id)
var acrName = '${resourcePrefix}acr${nameSuffix}'
var logAnalyticsName = '${resourcePrefix}-${environmentName}-law-${nameSuffix}'
var appInsightsName = '${resourcePrefix}-${environmentName}-appi-${nameSuffix}'
var appServicePlanName = '${resourcePrefix}-${environmentName}-asp-${nameSuffix}'
var webAppName = '${resourcePrefix}-${environmentName}-app-${nameSuffix}'
var foundryName = '${resourcePrefix}-${environmentName}-foundry-${nameSuffix}'
var acrImage = 'zavastorefront:latest'

module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: acrSku
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.id
  }
}

module appService './modules/appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    sku: appServiceSku
    acrLoginServer: acr.outputs.loginServer
    containerImage: acrImage
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

module roleAssignment './modules/roleAssignment.bicep' = {
  name: 'acrPullRole'
  params: {
    principalId: appService.outputs.principalId
    scopeResourceId: acr.outputs.id
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
  }
}

output webAppName string = appService.outputs.webAppName
output acrLoginServer string = acr.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
