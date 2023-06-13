param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isLinuxOperatingSystem = ('linux' == toLower(properties.operatingSystemName))
var isServiceEnvironmentNotEmpty = !empty(properties.?serviceEnvironment ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource hostingEnvironmentRef 'Microsoft.Web/hostingEnvironments@2022-09-01' existing = if (isServiceEnvironmentNotEmpty) {
  name: properties.serviceEnvironment.name
  scope: resourceGroup((properties.serviceEnvironment.?subscriptionId ?? subscriptionId), (properties.serviceEnvironment.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
}): {
  name: sys.guid(serverFarm.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
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
