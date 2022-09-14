@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Disk Encryption Set.')
param identity object = {}
@description('Specifies the name of the key that the Azure Disk Encryption Set will get from the Azure Key Vault.')
param keyName string
@description('An object that encapsulates the properties of the Azure Key Vault that the Azure Disk Encryption Set will get its encryption key from.')
param keyVault object
@description('Specifies the version of the key that the Azure Disk Encryption Set will get from the Azure Key Vault.')
param keyVersion string = ''
@description('Specifies the location in which the Azure Disk Encryption Set resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Disk Encryption Set.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Disk Encryption Set.')
param tags object = {}

var keyVaultScope = resourceGroup(union({
    subscriptionId: subscription().subscriptionId
}, keyVault).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, keyVault).resourceGroupName)
var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource keyVaultKeyRef 'Microsoft.KeyVault/vaults/keys@2022-07-01' existing  = if (empty(keyVersion)) {
    name: '${keyVault.name}/${keyName}'
    scope: keyVaultScope
}
resource keyVaultRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
    name: keyVault.name
    scope: keyVaultScope
}
resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-03-02' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        activeKey: {
            keyUrl: keyVaultKeyRef.properties.keyUriWithVersion
            sourceVault: {
                id: keyVaultRef.id
            }
        }
        encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
        rotationToLatestKeyVersionEnabled: true
    }
    tags: tags
}
