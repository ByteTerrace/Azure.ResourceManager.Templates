param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var identity = (properties.?identity ?? {})
var isIdentityNotEmpty = !empty(properties.?identity ?? {})
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(properties.?identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((properties.identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (properties.identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', properties.identity.userAssignedIdentities[index].name)
  index: index
}), (x, y) => (x.index < y.index))

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  location: location
  name: name
  properties: {
    activeKey: {
      keyUrl: keyRef.properties.keyUriWithVersion
    }
    encryptionType: properties.encryptionType
    rotationToLatestKeyVersionEnabled: true
  }
  tags: tags
}
resource keyRef 'Microsoft.KeyVault/vaults/keys@2023-02-01' existing = {
  name: '${properties.keyVault.name}/${properties.keyName}'
  scope: resourceGroup((properties.keyVault.?subscriptionId ?? subscriptionId), (properties.keyVault.?resourceGroupName ?? resourceGroupName))
}
