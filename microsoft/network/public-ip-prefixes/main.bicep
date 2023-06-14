param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isCustomPrefixNotEmpty = !empty(properties.?customPrefix ?? {})
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

resource customPrefixRef 'Microsoft.Network/customIpPrefixes@2022-11-01' existing = if (isCustomPrefixNotEmpty) {
  name: properties.customPrefix.name
  scope: resourceGroup((properties.customPrefix.?subscriptionId ?? subscriptionId), (properties.customPrefix.?resourceGroupName ?? resourceGroupName))
}
resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2022-11-01' = {
  location: location
  name: name
  properties: {
    customIPPrefix: (isCustomPrefixNotEmpty ? { id: customPrefixRef.id } : null)
    prefixLength: properties.length
    publicIPAddressVersion: (properties.?version ?? 'IPv4')
  }
  sku: properties.sku
  tags: tags
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(publicIpPrefix.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: publicIpPrefix
}]
