param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var identity = (properties.?identity ?? {})
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = items(identity.?userAssignedIdentities ?? {})
var userAssignedIdentitiesWithResourceId = [for (identity, index) in userAssignedIdentities: {
  index: index
  isPrimary: (identity.value.?isPrimary ?? (1 == length(userAssignedIdentities)))
  resourceId: userAssignedIdentitiesRef[index].id
}]

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  identity: {
    type: (identity.?type ?? (isUserAssignedIdentitiesNotEmpty ? 'UserAssigned' : 'None'))
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty? toObject(userAssignedIdentitiesWithResourceId, identity => identity.resourceId, identity => {}) : null)
  }
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
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.key
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
