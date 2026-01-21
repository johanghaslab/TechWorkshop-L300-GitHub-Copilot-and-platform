param principalId string
param scopeResourceId string

// AcrPull built-in role definition ID
var acrPullRoleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource scopeResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  id: scopeResourceId
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scopeResourceId, principalId, acrPullRoleDefinitionId)
  scope: scopeResource
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}
