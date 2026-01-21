param logAnalyticsWorkspaceId string
param location string = resourceGroup().location
param workbookDisplayName string = 'AI Services Observability'

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid(resourceGroup().id, workbookDisplayName)
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: loadTextContent('workbook.json')
    version: '1.0'
    category: 'workbook'
    sourceId: logAnalyticsWorkspaceId
  }
}

output workbookId string = workbook.id
