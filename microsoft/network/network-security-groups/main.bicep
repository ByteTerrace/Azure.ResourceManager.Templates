param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

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
var securityRules = (properties.?securityRules ?? [])
var subscriptionId = subscription().subscriptionId

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  location: location
  name: name
  properties: {
    securityRules: [for (rule, index) in sort(items(securityRules), (x, y) => (x.key < y.key)): {
      name: rule.key
      properties: {
        access: rule.value.access
        description: (rule.value.?description ?? null)
        destinationAddressPrefix: ((1 == length(rule.value.destination.addressPrefixes)) ? first(rule.value.destination.addressPrefixes) : null)
        destinationAddressPrefixes: ((1 == length(rule.value.destination.addressPrefixes)) ? null : rule.value.destination.addressPrefixes)
        destinationApplicationSecurityGroups: (contains(rule.value.destination, 'applicationSecurityGroups') ? map(rule.value.destination.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        destinationPortRange: ((1 == length(rule.value.destination.ports)) ? first(rule.value.destination.ports) : null)
        destinationPortRanges: ((1 == length(rule.value.destination.ports)) ? null : rule.value.destination.ports)
        direction: rule.value.direction
        priority: ((1949 - length(securityRules)) + index)
        protocol: rule.value.protocol
        sourceAddressPrefix: ((1 == length(rule.value.source.addressPrefixes)) ? first(rule.value.source.addressPrefixes) : null)
        sourceAddressPrefixes: ((1 == length(rule.value.source.addressPrefixes)) ? null : rule.value.source.addressPrefixes)
        sourceApplicationSecurityGroups: (contains(rule.value.source, 'applicationSecurityGroups') ? map(rule.value.source.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        sourcePortRange: ((1 == length(rule.value.source.ports)) ? first(rule.value.source.ports) : null)
        sourcePortRanges: ((1 == length(rule.value.source.ports)) ? null : rule.value.source.ports)
      }
    }]
  }
  tags: tags
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(networkSecurityGroup.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: networkSecurityGroup
}]
