@description('Microsoft Foundry (Azure OpenAI) account name')
param foundryAccountName string

@description('Location for the Foundry account')
param location string

@description('Deployment name for GPT-4 model')
param gptDeploymentName string

@description('Deployment name for Phi model')
param phiDeploymentName string

@description('GPT-4 model name (e.g. gpt-4)')
param gptModelName string

@description('GPT-4 model version')
param gptModelVersion string

@description('Phi model name (e.g. phi-4)')
param phiModelName string

@description('Phi model version')
param phiModelVersion string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: foundryAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource gptDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: gptDeploymentName
  parent: foundryAccount
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName
      version: gptModelVersion
    }
    raiPolicyName: 'Microsoft.Default'
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: phiDeploymentName
  parent: foundryAccount
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: phiModelName
      version: phiModelVersion
    }
    raiPolicyName: 'Microsoft.Default'
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

output foundryAccountId string = foundryAccount.id
output foundryAccountName string = foundryAccount.name
output foundryEndpoint string = foundryAccount.properties.endpoint
