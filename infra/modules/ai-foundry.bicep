// AI Foundry: AI Hub + Project + Model Deployments
param location string
param app string
param env string
param storageAccountId string
param keyVaultId string
param logAnalyticsWorkspaceId string
param managedIdentityPrincipalId string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2023-04-01-preview' = {
  name: 'aih-${app}-${env}'
  location: location
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: 'aih-${app}-${env}'
    description: 'AI Foundry Hub for ${app} ${env}'
    storageAccount: storageAccountId
    keyVault: keyVaultId
    systemDatastoresAuthMode: 'identity'
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Diagnostic settings: send all logs to Log Analytics
// Diagnostic settings not deployed: no supported log categories for MachineLearningServices/workspaces

// Assign Cognitive Services User role to App Service managed identity
resource aiHubContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiHub.id, 'Contributor')
  scope: aiHub
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Example: Add OpenAI model deployments as needed
// (You may need to add additional resources for GPT-4 and Phi models)
