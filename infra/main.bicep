// Main orchestration Bicep file for ZavaStorefront Dev Environment
// All resources are deployed in a single resource group in swedencentral

param location string = 'swedencentral'
param env string = 'dev'
param app string = 'zavasf'

// User Assigned Managed Identity
module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    location: location
    name: 'id-${app}-${env}'
  }
}

// Log Analytics + App Insights
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    app: app
    env: env
  }
}

// Azure Container Registry
module acr 'modules/container-registry.bicep' = {
  name: 'acr'
  params: {
    location: location
    name: 'acr${app}${env}'
    managedIdentityId: identity.outputs.identityId
    principalId: identity.outputs.principalId
  }
}

// App Service Plan + Web App
module appService 'modules/app-service.bicep' = {
  name: 'appService'
  params: {
    location: location
    app: app
    env: env
    acrLoginServer: acr.outputs.loginServer
    managedIdentityId: identity.outputs.identityId
    imageName: 'zavastorefront'
    imageTag: 'latest'
    appInsightsKey: monitoring.outputs.appInsightsKey
  }
  dependsOn: [acr]
}

// Storage Account for AI Foundry
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    name: 'st${app}${env}'
  }
}

// Key Vault
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    location: location
    name: 'kv-${app}-${env}'
    managedIdentityId: identity.outputs.identityId
  }
}

// AI Foundry (AI Hub + Project + Model Deployments)
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'aiFoundry'
  params: {
    location: location
    app: app
    env: env
    storageAccountId: storage.outputs.storageAccountId
    keyVaultId: keyVault.outputs.keyVaultId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    managedIdentityPrincipalId: identity.outputs.principalId
  }
}
