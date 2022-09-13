@description('Specifies the duration, in days, that data will be retained within the Azure Operational Insights Workspace.')
param dataRetentionInDays int = 30
@description('Indicates whether the data export feature is enabled on the Azure Operational Insights Workspace.')
param isDataExportEnabled bool = true
@description('Indicates whether data within the Azure Operational Insights Workspace that is older than 30 days will be immediately purged.')
param isImmediatePurgeDataOn30DaysEnabled bool = true
@description('Indicates whether public network access is permitted to the Azure Operational Insights Workspace when ingesting data.')
param isPublicNetworkAccessForIngestionEnabled bool = false
@description('Indicates whether public network access is permitted to the Azure Operational Insights Workspace when querying data.')
param isPublicNetworkAccessForQueryEnabled bool = false
@description('Specifies the location in which the Azure Log Analytics Workspace resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Log Analytics Workspace.')
param name string
@description('Specifies the SKU name of the Azure Log Analytics Workspace.')
param skuName string = 'PerGB2018'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
    location: location
    name: name
    properties: {
        features: {
            disableLocalAuth: true
            enableDataExport: isDataExportEnabled
            enableLogAccessUsingOnlyResourcePermissions: true
            immediatePurgeDataOn30Days: isImmediatePurgeDataOn30DaysEnabled
        }
        publicNetworkAccessForIngestion: isPublicNetworkAccessForIngestionEnabled ? 'Enabled' : 'Disabled'
        publicNetworkAccessForQuery: isPublicNetworkAccessForQueryEnabled ? 'Enabled' : 'Disabled'
        retentionInDays: dataRetentionInDays
        sku: {
            name: skuName
        }
        workspaceCapping: {
            dailyQuotaGb: -1
        }
    }
}
