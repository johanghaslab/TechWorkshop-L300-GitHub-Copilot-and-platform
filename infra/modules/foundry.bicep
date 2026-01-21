param name string
param location string
param skuName string = 'S0'

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: name
  }
}

output id string = foundry.id
output endpoint string = foundry.properties.endpoint
