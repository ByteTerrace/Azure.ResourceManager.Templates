@description('Specifies the duration, in days, that data will be retained within the Azure Log Analytics Workspace.')
param dataRetentionInDays int = 30
@description('Indicates whether the data export feature is enabled on the Azure Log Analytics Workspace.')
param isDataExportEnabled bool = true
@description('Indicates whether data within the Azure Log Analytics Workspace that is older than 30 days will be immediately purged.')
param isImmediatePurgeDataOn30DaysEnabled bool = true
@description('Indicates whether public network access is permitted to the Azure Log Analytics Workspace when ingesting data.')
param isPublicNetworkAccessForIngestionEnabled bool = false
@description('Indicates whether public network access is permitted to the Azure Log Analytics Workspace when querying data.')
param isPublicNetworkAccessForQueryEnabled bool = false
@description('Indicates whether shared keys are able to be used to access the Azure Log Analytics Workspace.')
param isSharedKeyAccessEnabled bool = false
@description('Specifies the location in which the Azure Log Analytics Workspace resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Log Analytics Workspace.')
param name string
@description('Specifies the SKU of the Azure Log Analytics Workspace.')
param sku object = {
    name: 'PerGB2018'
}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Log Analytics Workspace.')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
    location: location
    name: name
    properties: {
        features: {
            disableLocalAuth: !isSharedKeyAccessEnabled
            enableDataExport: isDataExportEnabled
            enableLogAccessUsingOnlyResourcePermissions: true
            immediatePurgeDataOn30Days: isImmediatePurgeDataOn30DaysEnabled
        }
        publicNetworkAccessForIngestion: isPublicNetworkAccessForIngestionEnabled ? 'Enabled' : 'Disabled'
        publicNetworkAccessForQuery: isPublicNetworkAccessForQueryEnabled ? 'Enabled' : 'Disabled'
        retentionInDays: dataRetentionInDays
        sku: sku
        workspaceCapping: {
            dailyQuotaGb: -1
        }
    }
    tags: tags
}
