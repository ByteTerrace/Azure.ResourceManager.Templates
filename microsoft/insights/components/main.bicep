param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource component 'Microsoft.Insights/components@2020-02-02' = {
  kind: 'web'
  location: location
  name: name
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
  tags: tags
}
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: properties.logAnalyticsWorkspace.name
  scope: resourceGroup((properties.logAnalyticsWorkspace.?subscriptionId ?? subscriptionId), (properties.logAnalyticsWorkspace.?resourceGroupName ?? resourceGroupName))
}
