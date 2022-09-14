@description('Specifies the location in which the Azure Application Insights resource(s) will be deployed.')
param location string = resourceGroup().location
@description('An object that encapsulates the properties of the Azure Log Analytics Workspace that the Azure Application Insights will be associated with.')
param logAnalyticsWorkspace object
@description('Specifies the name of the Azure Application Insights.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Application Insights.')
param tags object = {}

resource component 'Microsoft.Insights/components@2020-02-02' = {
    kind: 'web'
    location: location
    name: name
    properties: {
        Application_Type: 'web'
        Flow_Type: 'Bluefield'
        IngestionMode: 'LogAnalytics'
        Request_Source: 'IbizaAIExtension'
        WorkspaceResourceId: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, logAnalyticsWorkspace).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspace.name)
    }
    tags: tags
}
