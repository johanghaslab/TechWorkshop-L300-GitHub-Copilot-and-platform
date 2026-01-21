param name string
param location string
param sku string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}

output id string = acr.id
output loginServer string = acr.properties.loginServer
