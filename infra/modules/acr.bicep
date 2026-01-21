@description('Azure Container Registry name')
param acrName string

@description('Location for the registry')
param location string

resource registry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrId string = registry.id
output acrLoginServer string = registry.properties.loginServer
