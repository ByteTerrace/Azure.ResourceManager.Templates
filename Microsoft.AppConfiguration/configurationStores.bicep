@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Application Configuration Store.')
param identity object = {}
@description('Indicates whether the Azure Application Configuration Store is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the purge protection feature is enabled on the Azure Application Configuration Store.')
param isPurgeProtectionEnabled bool = true
@description('Specifies the location in which the Azure Application Configuration Store resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Configuration Store.')
param name string
@description('An object that encapsulates the set of settings that will be stored within the Azure Application Configuration Store.')
@secure()
param settings object = {}
@description('Specifies the SKU name of the Azure Application Configuration Store.')
param skuName string = 'Premium'

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource configurationStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        disableLocalAuth: false
        enablePurgeProtection: isPurgeProtectionEnabled
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        softDeleteRetentionInDays: ('free' == toLower(skuName)) ? null : 14
    }
    sku: {
        name: skuName
    }
}
resource keyVaultSecretReferencesCopy 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = [for setting in items(settings): if (!empty(union({ keyVault: {} }, setting.value).keyVault)) {
    name: '${setting.value.keyVault.name}/${setting.value.keyVault.secretName}'
    scope: resourceGroup(subscription().subscriptionId, resourceGroup().name)
}]
resource settingsCopy 'Microsoft.AppConfiguration/configurationStores/keyValues@2022-05-01' = [for (setting, index) in items(settings): {
    dependsOn: [
        keyVaultSecretReferencesCopy
    ]
    name: setting.key
    parent: configurationStore
    properties: {
        contentType: empty(union({ keyVault: {} }, setting.value).keyVault) ? union({ contentType: null }, setting.value).contentType : 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        tags: union({ tags: {} }, setting.value).tags
        value: empty(union({ keyVault: {} }, setting.value).keyVault) ? setting.value.value : string({ uri: keyVaultSecretReferencesCopy[index].properties.secretUri })
    }
}]
