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
var subscriptionId = subscription().subscriptionId

resource hostingEnvironment 'Microsoft.Web/hostingEnvironments@2022-09-01' = {
  location: location
  name: name
  properties: {
    clusterSettings: union([{
      name: 'DisabledTls1.0'
      value: '1'
    }], ((properties.?isInternalEncryptionEnabled ?? false) ? [{
      name: 'InternalEncryption'
      value: 'true'
    }] : []), ((properties.?isMinimalSslCipherSuiteConfigurationEnabled ?? true) ? [{
      name: 'FrontEndSSLCipherSuiteOrder'
      value: 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
    }] : []))
    internalLoadBalancingMode: 'Web, Publishing'
    virtualNetwork: { id: subnetRef.id }
    zoneRedundant: (properties.?isZoneRedundancyEnabled ?? null)
  }
  tags: tags
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(hostingEnvironment.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: hostingEnvironment
}]
resource subnetRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: '${properties.subnet.virtualNetworkName}/${properties.subnet.name}'
  scope: resourceGroup((properties.subnet.?subscriptionId ?? subscriptionId), (properties.subnet.?resourceGroupName ?? resourceGroupName))
}
