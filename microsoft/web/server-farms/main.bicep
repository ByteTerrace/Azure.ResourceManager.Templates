param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isLinuxOperatingSystem = ('linux' == toLower(properties.operatingSystemName))
var isServiceEnvironmentNotEmpty = !empty(properties.?serviceEnvironment ?? {})
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
var subscriptionId = subscription().subscriptionId

resource hostingEnvironmentRef 'Microsoft.Web/hostingEnvironments@2022-09-01' existing = if (isServiceEnvironmentNotEmpty) {
  name: properties.serviceEnvironment.name
  scope: resourceGroup((properties.serviceEnvironment.?subscriptionId ?? subscriptionId), (properties.serviceEnvironment.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(serverFarm.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: serverFarm
}]
resource serverFarm 'Microsoft.Web/serverfarms@2022-09-01' = {
  location: location
  name: name
  properties: {
    hostingEnvironmentProfile: (isServiceEnvironmentNotEmpty ? { id: hostingEnvironmentRef.id } : null)
    perSiteScaling: (properties.?isPerSiteScalingEnabled ?? null)
    reserved: (isLinuxOperatingSystem ? true : null)
    zoneRedundant: (properties.?isZoneRedundancyEnabled ?? null)
  }
  sku: properties.sku
  tags: tags
}
