param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var firewallRules = (properties.?firewallRules ?? [])
var identity = (properties.?identity ?? {})
var isAllowTrustedMicrosoftServicesEnabled = (properties.?isAllowTrustedMicrosoftServicesEnabled ?? false)
var isIdentityNotEmpty = !empty(identity)
var isPremiumSku = ('premium' == toLower(properties.sku.name))
var isPublicNetworkAccessEnabled = (properties.?isPublicNetworkAccessEnabled ?? false)
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
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
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))

resource privateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource registry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  location: location
  name: name
  properties: {
    adminUserEnabled: (properties.?isSharedKeyAccessEnabled ?? false)
    #disable-next-line BCP037
    anonymousPullEnabled: (properties.?isAnonymousPullEnabled ?? false)
    dataEndpointEnabled: (properties.?isDedicatedDataEndpointEnabled ?? false)
    encryption: null
    networkRuleBypassOptions: (isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None')
    networkRuleSet: (isPremiumSku ? {
      defaultAction: ((isPublicNetworkAccessEnabled && empty(firewallRules)) ? 'Allow' : 'Deny')
      ipRules: map(firewallRules, rule => {
        action: 'Allow'
        value: rule
      })
    } : null)
    policies: {
      exportPolicy: {
        status: ((properties.?isExportPolicyEnabled ?? false) ? 'enabled' : 'disabled')
      }
      quarantinePolicy: {
        status: ((properties.?isQuarantinePolicyEnabled ?? true) ? 'enabled' : 'disabled')
      }
      trustPolicy: {
        status: ((properties.?isContentTrustPolicyEnabled ?? true) ? 'enabled' : 'disabled')
        type: 'Notary'
      }
    }
    publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled')
    zoneRedundancy: ((properties.?isZoneRedundancyEnabled ?? false) ? 'Enabled' : 'Disabled')
  }
  sku: properties.sku
  tags: tags
}
resource registryPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in privateEndpoints: {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'registry' ]
        privateLinkServiceId: registry.id
      }
    }]
    subnet: { id: privateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource registryRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(registry.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: registry
}]
