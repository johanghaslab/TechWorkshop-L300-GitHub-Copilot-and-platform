# AI Services Observability Workbook

## Overview
This module deploys an Azure Workbook for monitoring AI Services performance and usage patterns.

## Files
- **workbook.bicep**: Bicep template that deploys the Azure Workbook resource
- **workbook-template.json**: Workbook definition containing the visualizations and queries

## Visualizations Included

### 1. Request Volume
- **Query**: Counts requests over time in 5-minute bins
- **Visualization**: Time chart showing request volume over the last hour

### 2. Latency Percentiles
- **Query**: Calculates P50, P90, P95, and P99 latency percentiles
- **Visualization**: Time chart showing latency trends over time

### 3. Breakdown by Operation Name
- **Query**: Groups requests by operation name with count and average duration
- **Visualization**: Table showing top 10 operations by request count

## Usage

To deploy the workbook as part of your infrastructure:

```bicep
module aiWorkbook 'modules/workbook.bicep' = {
  name: 'aiWorkbook'
  params: {
    location: location
    workbookName: 'AI Services Observability'
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
  }
}
```

## Data Source
The workbook queries data from a Log Analytics workspace, using the `requests` table which is populated by Application Insights.

## Customization
To customize the queries or visualizations, edit the `workbook-template.json` file. The workbook uses KQL (Kusto Query Language) for data queries.
