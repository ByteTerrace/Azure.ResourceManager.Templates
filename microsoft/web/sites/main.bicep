param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var applicationSettings = (properties.?applicationSettings ?? {})
var connectionStrings = (properties.?connectionStrings ?? {})
var crossOriginResourceSharing = (properties.?crossOriginResourceSharing ?? {})
var functionExtension = (properties.?functionExtension ?? {})
var healthCheck = (properties.?healthCheck ?? {})
var identity = (properties.?identity ?? {})
var isApplicationInsightsNotEmpty = !empty(properties.?applicationInsights ?? {})
var isDotNetFrameworkApp = startsWith(properties.frameworkVersion, 'dotnet')
var isFunctionApplication = !empty(functionExtension)
var isHealthCheckEnabled = (healthCheck.?isEnabled ?? !empty(healthCheck))
var isIdentityNotEmpty = !empty(identity)
var isNodeJsApp = startsWith(properties.frameworkVersion, 'node')
var isSlotNameNotEmpty = !empty(properties.?slotName ?? '')
var isSubnetNotEmpty = !empty(properties.?subnet ?? {})
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var operatingSystemType = servicePlanRef.kind
var resourceGroupName = resourceGroup().name
var siteKind = '${(isFunctionApplication ? 'function' : '')}app'
var siteProperties = {
  clientAffinityEnabled: (properties.?isClientAffinityEnabled ?? false)
  httpsOnly: (properties.?isHttpsOnlyModeEnabled ?? true)
  publicNetworkAccess: ((properties.?isPublicNetworkAccessEnabled ?? false) ? 'Enabled' : 'Disabled')
  serverFarmId: servicePlanRef.id
  siteConfig: {
    alwaysOn: (properties.?isAlwaysOnEnabled ?? null)
    appSettings: union(
      (isApplicationInsightsNotEmpty ? [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsRef.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsRef.properties.ConnectionString
        }
      ] : []),
      (isFunctionApplication ? union(
        [
          {
            name: 'AzureWebJobsStorage__accountName'
            value: functionStorageAccount.name
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: (functionExtension.?version ?? '~4')
          }
        ],
        (isNodeJsApp ? [
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'node'
          }
        ] : [
      ])) : []),
      map(items(applicationSettings), setting => {
        name: setting.key
        value: setting.value.value
      })
    )
    connectionStrings: map(items(connectionStrings), connectionString => {
      connectionString: connectionString.value.value
      name: connectionString.key
      type: connectionString.value.type
    })
    cors: {
      allowedOrigins: union((isFunctionApplication ? [ 'https://portal.azure.com' ] : []), (crossOriginResourceSharing.?allowedOrigins ?? []))
      supportCredentials: (crossOriginResourceSharing.?isCredentialSupportEnabled ?? false)
    }
    ftpsState: 'FtpsOnly'
    http20Enabled: (properties.?isHttp20SupportEnabled ?? null)
    linuxFxVersion: (('linux' == toLower(operatingSystemType)) ? (isDotNetFrameworkApp ? replace(properties.frameworkVersion, 'DOTNET', 'DOTNETCORE') : (isNodeJsApp ? '${properties.frameworkVersion}-lts' : null)) : null)
    metadata: [{
      name: 'CURRENT_STACK'
      value: (isDotNetFrameworkApp ? 'dotnet' : (isNodeJsApp ? 'node' : null))
    }]
    netFrameworkVersion: (isDotNetFrameworkApp ? 'v${first(last(any(split(properties.frameworkVersion, '|'))))}.0' : null)
    remoteDebuggingEnabled: (properties.?isRemoteDebuggingEnabled ?? null)
    remoteDebuggingVersion: (properties.?remoteDebugging.?version ?? null)
    use32BitWorkerProcess: (properties.?is32BitModeEnabled ?? isFunctionApplication)
    webSocketsEnabled: (properties.?isWebSocketSupportEnabled ?? false)
  }
  virtualNetworkSubnetId: (isSubnetNotEmpty ? virtualNetworkIntegrationSubnet.id : null)
}
var siteTags = union((isApplicationInsightsNotEmpty ? {
  'hidden-link: /app-insights-resource-id': applicationInsightsRef.id
} : {}), tags)
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))
var virtualApplications = (properties.?virtualApplications ?? {})

resource applicationInsightsRef 'Microsoft.Insights/components@2020-02-02' existing = if (isApplicationInsightsNotEmpty) {
  name: properties.applicationInsights.name
  scope: resourceGroup((properties.applicationInsights.?subscriptionId ?? subscriptionId), (properties.applicationInsights.?resourceGroupName ?? resourceGroupName))
}
resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (false) {
  name: properties.functionExtension.storageAccount.name
  scope: resourceGroup((properties.functionExtension.?storageAccount.?subscriptionId ?? subscription().subscriptionId), (properties.functionExtension.?storageAccount.?resourceGroupName ?? resourceGroup().name))
}
resource parentSite 'Microsoft.Web/sites@2022-09-01' existing = if (isSlotNameNotEmpty) {
  name: name
}
resource servicePlanRef 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: properties.servicePlan.name
  scope: resourceGroup((properties.servicePlan.?subscriptionId ?? subscription().subscriptionId), (properties.servicePlan.?resourceGroupName ?? resourceGroup().name))
}
resource site 'Microsoft.Web/sites@2022-09-01' = if (!isSlotNameNotEmpty) {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  kind: siteKind
  location: location
  name: name
  properties: siteProperties
  tags: siteTags
}
resource slot 'Microsoft.Web/sites/slots@2022-09-01' = if (isSlotNameNotEmpty) {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  kind: siteKind
  location: location
  name: properties.slotName
  parent: parentSite
  properties: siteProperties
  tags: siteTags
}
resource webConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'web'
  parent: site
  properties: {
    healthCheckPath: (isHealthCheckEnabled ? (healthCheck.?path ?? '/health-check') : '')
    minTlsVersion: '1.2'
    virtualApplications: (empty(virtualApplications) ? null : map(virtualApplications, application => {
      physicalPath: application.physicalPath
      preloadEnabled: (application.?isPreloadEnabled ?? null)
      virtualDirectories: (application.?virtualDirectories ?? null)
      virtualPath: application.virtualPath
    }))
  }
}
resource virtualNetworkIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = if (isSubnetNotEmpty) {
  name: '${properties.subnet.virtualNetworkName}/${properties.subnet.name}'
  scope: resourceGroup((properties.subnet.?subscriptionId ?? subscription().subscriptionId), (properties.subnet.?resourceGroupName ?? resourceGroup().name))
}
