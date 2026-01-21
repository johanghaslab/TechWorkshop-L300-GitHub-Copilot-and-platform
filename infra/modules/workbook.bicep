// Azure Workbook for AI Services Observability
param location string
param workbookName string = 'AI Services Observability'
param logAnalyticsWorkspaceId string

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(workbookName, resourceGroup().id)
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookName
    serializedData: string(loadJsonContent('workbook-template.json'))
    version: '1.0'
    sourceId: logAnalyticsWorkspaceId
    category: 'AI Services'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.properties.displayName
