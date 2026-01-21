param name string
@allowed([
  'swedencentral'
])
param location string

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
  }
}

output id string = foundry.id
output endpoint string = foundry.properties.endpoint
