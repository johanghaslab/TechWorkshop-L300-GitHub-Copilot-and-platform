param principalId string
param scopeResourceId string

var roleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource scopeResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  id: scopeResourceId
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scopeResourceId, principalId, roleDefinitionId)
  scope: scopeResource
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}
