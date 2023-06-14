param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isPrefixNotEmpty = !empty(properties.?prefix ?? {})
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

resource ipAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  location: location
  name: name
  properties: {
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
    deleteOption: (properties.?deleteOption ?? 'Detach')
    idleTimeoutInMinutes: (properties.?idleTimeoutInMinutes ?? null)
    publicIPAddressVersion: (properties.?version ?? 'IPv4')
    publicIPAllocationMethod: (properties.?allocationMethod ?? 'Static')
    publicIPPrefix: (isPrefixNotEmpty ? { id: ipPrefixRef.id } : null)
  }
  sku: properties.sku
  tags: tags
}
resource ipPrefixRef 'Microsoft.Network/publicIPPrefixes@2022-11-01' existing = if (isPrefixNotEmpty) {
  name: properties.prefix.name
  scope: resourceGroup((properties.prefix.?subscriptionId ?? subscriptionId), (properties.prefix.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(ipAddress.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: ipAddress
}]
