param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var applicationSettings = items(properties.?applicationSettings ?? {})
var connectionStrings = items(properties.?connectionStrings ?? {})
var crossOriginResourceSharing = (properties.?crossOriginResourceSharing ?? {})
var customDomains = items(properties.?customDomains ?? {})
var functionExtension = (properties.?functionExtension ?? {})
var healthCheck = (properties.?healthCheck ?? {})
var identity = (properties.?identity ?? {})
var isApplicationInsightsNotEmpty = !empty(properties.?applicationInsights ?? {})
var isDotNetFrameworkApp = startsWith(properties.frameworkVersion, 'dotnet')
var isFunctionApplication = !empty(functionExtension)
var isHealthCheckEnabled = (healthCheck.?isEnabled ?? !empty(healthCheck))
var isNodeJsApp = startsWith(properties.frameworkVersion, 'node')
var isSlotNameNotEmpty = !empty(properties.?slotName ?? '')
var isSubnetNotEmpty = !empty(properties.?subnet ?? {})
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var operatingSystemType = servicePlanRef.kind
var privateEndpoints = items(properties.?privateEndpoints ?? {})
var resourceGroupName = resourceGroup().name
var roleAssignmentsTransform = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  resource: (empty(assignment.resource) ? null : {
    apiVersion: assignment.resource.apiVersion
    id: '/subscriptions/${(assignment.resource.?subscriptionId ?? subscriptionId)}/resourceGroups/${(assignment.resource.?resourceGroupName ?? resourceGroupName)}/providers/${assignment.resource.type}/${assignment.resource.path}'
    type: assignment.resource.type
  })
  roleDefinitionId: assignment.roleDefinitionId
})
var siteIdentity = {
  type: (identity.?type ?? (isUserAssignedIdentitiesNotEmpty ? 'UserAssigned' : 'None'))
  userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty? toObject(userAssignedIdentitiesWithResourceId, identity => identity.resourceId, identity => {}) : null)
}
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
      map(applicationSettings, setting => {
        name: setting.key
        value: setting.value.value
      })
    )
    connectionStrings: map(connectionStrings, connectionString => {
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
var userAssignedIdentities = items(identity.?userAssignedIdentities ?? {})
var userAssignedIdentitiesWithResourceId = [for (identity, index) in userAssignedIdentities: {
  index: index
  isPrimary: (identity.value.?isPrimary ?? (1 == length(userAssignedIdentities)))
  resourceId: userAssignedIdentitiesRef[index].id
}]
var virtualApplications = (properties.?virtualApplications ?? {})

resource applicationInsightsRef 'Microsoft.Insights/components@2020-02-02' existing = if (isApplicationInsightsNotEmpty) {
  name: properties.applicationInsights.name
  scope: resourceGroup((properties.applicationInsights.?subscriptionId ?? subscriptionId), (properties.applicationInsights.?resourceGroupName ?? resourceGroupName))
}
resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (isFunctionApplication) {
  name: properties.functionExtension.storageAccount.name
  scope: resourceGroup((properties.functionExtension.?storageAccount.?subscriptionId ?? subscription().subscriptionId), (properties.functionExtension.?storageAccount.?resourceGroupName ?? resourceGroup().name))
}
resource privateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource servicePlanRef 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: properties.servicePlan.name
  scope: resourceGroup((properties.servicePlan.?subscriptionId ?? subscription().subscriptionId), (properties.servicePlan.?resourceGroupName ?? resourceGroup().name))
}
resource site 'Microsoft.Web/sites@2022-09-01' = if (!isSlotNameNotEmpty) {
  identity: siteIdentity
  kind: siteKind
  location: location
  name: name
  properties: siteProperties
  tags: siteTags
}
@batchSize(1)
resource siteHostNameBindings 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = [for domain in customDomains: if (!isSlotNameNotEmpty) {
  name: domain.key
  parent: site
  properties: {
    sslState: 'Disabled'
    thumbprint: null
  }
}]
resource sitePrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in privateEndpoints: if (!isSlotNameNotEmpty) {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'sites' ]
        privateLinkServiceId: site.id
      }
    }]
    subnet: { id: privateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource siteRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: if (!isSlotNameNotEmpty) {
  name: sys.guid(site.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: site
}]
resource siteSlotConfigNamesConfig 'Microsoft.Web/sites/config@2022-09-01' = if (!isSlotNameNotEmpty) {
  name: 'slotConfigNames'
  parent: site
  properties: {
    appSettingNames: map(filter(applicationSettings, setting => (setting.value.?isStickinessEnabled ?? false)), setting => setting.key)
    azureStorageConfigNames: null
    connectionStringNames: map(filter(connectionStrings, string => (string.value.?isStickinessEnabled ?? false)), string => string.key)
  }
}
resource siteWebConfig 'Microsoft.Web/sites/config@2022-09-01' = if (!isSlotNameNotEmpty) {
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
resource slot 'Microsoft.Web/sites/slots@2022-09-01' = if (isSlotNameNotEmpty) {
  identity: siteIdentity
  kind: siteKind
  location: location
  name: (properties.?slotName ?? 'default')
  parent: slotSite
  properties: siteProperties
  tags: siteTags
}
@batchSize(1)
resource slotHostNameBindings 'Microsoft.Web/sites/slots/hostNameBindings@2022-09-01' = [for domain in customDomains: if (isSlotNameNotEmpty) {
  name: domain.key
  parent: slot
  properties: {
    sslState: 'Disabled'
    thumbprint: null
  }
}]
resource slotPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in privateEndpoints: if (isSlotNameNotEmpty) {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'sites-${site.name}' ]
        privateLinkServiceId: site.id
      }
    }]
    subnet: { id: privateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource slotRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: if (isSlotNameNotEmpty) {
  name: sys.guid(slot.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: slot
}]
resource slotSite 'Microsoft.Web/sites@2022-09-01' existing = if (isSlotNameNotEmpty) {
  name: name
}
resource slotWebConfig 'Microsoft.Web/sites/slots/config@2022-09-01' = if (isSlotNameNotEmpty) {
  name: 'web'
  parent: slot
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
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.key
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
resource virtualNetworkIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = if (isSubnetNotEmpty) {
  name: '${properties.subnet.virtualNetworkName}/${properties.subnet.name}'
  scope: resourceGroup((properties.subnet.?subscriptionId ?? subscription().subscriptionId), (properties.subnet.?resourceGroupName ?? resourceGroup().name))
}
