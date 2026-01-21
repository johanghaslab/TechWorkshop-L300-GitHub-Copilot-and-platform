// AI Foundry: AI Hub + Project + Model Deployments
param location string
param app string
param env string
param storageAccountId string
param keyVaultId string

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

// Example: Add OpenAI model deployments as needed
// (You may need to add additional resources for GPT-4 and Phi models)
