@description('Deployment location')
@allowed([
  'swedencentral'
])
param location string = 'swedencentral'

@description('Environment name for resource naming')
param environmentName string = 'dev'

@description('Container image name with tag stored in ACR')
param containerImageName string = 'zavastorefront:dev'

@description('Azure Container Registry name')
param acrName string = 'acrzava${uniqueString(resourceGroup().id)}'

@description('App Service plan name')
param appServicePlanName string = 'asp-zava-${environmentName}-${uniqueString(resourceGroup().id)}'

@description('Web App name')
param webAppName string = 'app-zava-${environmentName}-${uniqueString(resourceGroup().id)}'

@description('Log Analytics workspace name')
param logAnalyticsName string = 'log-zava-${environmentName}-${uniqueString(resourceGroup().id)}'

@description('Application Insights name')
param appInsightsName string = 'appi-zava-${environmentName}-${uniqueString(resourceGroup().id)}'

@description('Microsoft Foundry (Azure OpenAI) account name')
param foundryAccountName string = 'aizava${toLower(uniqueString(resourceGroup().id))}'

@description('GPT-4 deployment name')
param gptDeploymentName string = 'gpt4'

@description('Phi deployment name')
param phiDeploymentName string = 'phi'

@description('GPT-4 model name')
param gptModelName string = 'gpt-4'

@description('GPT-4 model version (update if swedencentral requires a different version)')
param gptModelVersion string = '0613'

@description('Phi model name')
param phiModelName string = 'phi-4'

@description('Phi model version (update if swedencentral requires a different version)')
param phiModelVersion string = '2024-10-01'

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    acrName: acrName
    location: location
  }
}

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    workspaceName: logAnalyticsName
    location: location
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    appInsightsName: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

module appService 'modules/appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    acrLoginServer: acr.outputs.acrLoginServer
    containerImageName: containerImageName
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    foundryAccountName: foundryAccountName
    location: location
    gptDeploymentName: gptDeploymentName
    phiDeploymentName: phiDeploymentName
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    phiModelName: phiModelName
    phiModelVersion: phiModelVersion
  }
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource foundryResource 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: foundryAccountName
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webAppName, acrName, 'acrpull')
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: appService.outputs.webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource foundryAccessAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webAppName, foundryAccountName, 'foundryuser')
  scope: foundryResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
    principalId: appService.outputs.webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output acrLoginServer string = acr.outputs.acrLoginServer
output webAppName string = appService.outputs.webAppName
output appInsightsName string = appInsights.outputs.appInsightsName
output foundryEndpoint string = foundry.outputs.foundryEndpoint

output AZURE_WEBAPP_NAME string = appService.outputs.webAppName
output AZURE_CONTAINER_REGISTRY_NAME string = acrName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.acrLoginServer
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.appInsightsConnectionString
