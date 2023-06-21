param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var blobServicesProperties = {
  containers: items(properties.?blobServices.?containers ?? {})
  isAnonymousAccessEnabled: false
  privateEndpoints: items(properties.?blobServices.?privateEndpoints ?? {})
}
var fileServicesProperties = {
  privateEndpoints: items(properties.?fileServices.?privateEndpoints ?? {})
  shares: items(properties.?fileServices.?shares ?? {})
}
var firewallRules = (properties.?firewallRules ?? [])
var identity = (properties.?identity ?? {})
var isIdentityNotEmpty = !empty(identity)
var isPublicNetworkAccessEnabled = (properties.?isPublicNetworkAccessEnabled ?? false)
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var queueServicesProperties = {
  encryptionServiceKeyType: (properties.?queueServices.?encryptionServiceKeyType ?? 'Account')
  privateEndpoints: items(properties.?queueServices.?privateEndpoints ?? {})
}
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
var tableServicesProperties = {
  encryptionServiceKeyType: (properties.?tableServices.?encryptionServiceKeyType ?? 'Account')
  privateEndpoints: items(properties.?tableServices.?privateEndpoints ?? {})
}
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))
var virtualNetworkRules = (properties.?virtualNetworkRules ?? [])

resource account 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  kind: (properties.?kind ?? 'StorageV2')
  location: location
  name: name
  properties: {
    accessTier: properties.accessTier
    allowBlobPublicAccess: blobServicesProperties.isAnonymousAccessEnabled
    allowSharedKeyAccess: (properties.?isSharedKeyAccessEnabled ?? false)
    defaultToOAuthAuthentication: true
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: queueServicesProperties.encryptionServiceKeyType
        }
        table: {
          enabled: true
          keyType: tableServicesProperties.encryptionServiceKeyType
        }
      }
    }
    isHnsEnabled: (properties.?isHierarchicalNamespaceEnabled ?? null)
    isLocalUserEnabled: null
    isNfsV3Enabled: (properties.?isNetworkFileSystemV3Enabled ?? null)
    isSftpEnabled: (properties.?isSecureFileTransferProtocolEnabled ?? null)
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: ((properties.?isAllowTrustedMicrosoftServicesEnabled ?? false) ? 'AzureServices' : 'None')
      defaultAction: ((isPublicNetworkAccessEnabled && empty(firewallRules) && empty(virtualNetworkRules)) ? 'Allow' : 'Deny')
      ipRules: [for rule in firewallRules: {
        action: 'Allow'
        value: rule
      }]
      virtualNetworkRules: [for (rule, index) in virtualNetworkRules: {
        action: 'Allow'
        id: virtualNetworkRulesSubnetsRef[index].id
      }]
    }
    publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled')
    supportsHttpsTrafficOnly: (properties.?isHttpsOnlyModeEnabled ?? true)
  }
  sku: properties.sku
  tags: tags
}
resource accountRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(account.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: account
}]
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: account
  properties: {}
}
resource blobServicesContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for container in blobServicesProperties.containers: {
  name: container.key
  parent: blobServices
  properties: {
    metadata: (container.value.?metadata ?? null)
  }
}]
resource blobServicesPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in blobServicesProperties.privateEndpoints: {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'blob' ]
        privateLinkServiceId: account.id
      }
    }]
    subnet: { id: blobServicesPrivateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource blobServicesPrivateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in blobServicesProperties.privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: account
  properties: {}
}
resource fileServicesPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in fileServicesProperties.privateEndpoints: {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'file' ]
        privateLinkServiceId: account.id
      }
    }]
    subnet: { id: fileServicesPrivateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource fileServicesPrivateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in queueServicesProperties.privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource fileServiceShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for share in blobServicesProperties.containers: {
  name: share.key
  parent: fileServices
  properties: {
    metadata: (share.value.?metadata ?? null)
  }
}]
resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = {
  name: 'default'
  parent: account
  properties: {}
}
resource queueServicesPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in queueServicesProperties.privateEndpoints: {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'queue' ]
        privateLinkServiceId: account.id
      }
    }]
    subnet: { id: queueServicesPrivateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource queueServicesPrivateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in queueServicesProperties.privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = {
  name: 'default'
  parent: account
  properties: {}
}
resource tableServicesPrivateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (endpoint, index) in tableServicesProperties.privateEndpoints: {
  name: endpoint.key
  properties: {
    privateLinkServiceConnections: [{
      name: endpoint.key
      properties: {
        groupIds: [ 'table' ]
        privateLinkServiceId: account.id
      }
    }]
    subnet: { id: tableServicesPrivateEndpointsSubnetsRef[index].id }
  }
  tags: tags
}]
resource tableServicesPrivateEndpointsSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in tableServicesProperties.privateEndpoints: {
  name: '${endpoint.value.subnet.virtualNetworkName}/${endpoint.value.subnet.name}'
  scope: resourceGroup((endpoint.value.subnet.?subscriptionId ?? subscription().subscriptionId), (endpoint.value.subnet.?resourceGroupName ?? resourceGroup().name))
}]
resource virtualNetworkRulesSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for rule in virtualNetworkRules: {
  name: '${rule.subnet.virtualNetworkName}/${rule.subnet.name}'
  scope: resourceGroup((rule.subnet.?subscriptionId ?? subscriptionId), (rule.subnet.?resourceGroupName ?? resourceGroupName))
}]
