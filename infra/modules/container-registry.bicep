// Azure Container Registry with RBAC
param location string
param name string
param managedIdentityId string
param principalId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// Assign AcrPull role to Managed Identity
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentityId, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output loginServer string = acr.properties.loginServer
output acrId string = acr.id
