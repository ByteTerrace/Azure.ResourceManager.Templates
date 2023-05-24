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
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))

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
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
}): {
  name: guid(registry.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
  }
  scope: registry
}]
