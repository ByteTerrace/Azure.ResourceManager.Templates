@description('Specifies the access tier of the Azure Storage Account.')
param accessTier string
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Storage Account.')
param identity object
@description('Indicates whether HTTP network protocol support is restricted to HTTPS on the Azure Storage Account.')
param isHttpsOnlyModeEnabled bool
@description('Indicates whether the Azure Storage Account is accessible from the internet.')
param isPublicNetworkAccessEnabled bool
@description('Indicates whether shared keys are able to be used to access the Azure Storage Account.')
param isSharedKeyAccessEnabled bool
@description('Specifies the kind of the Azure Storage Account.')
param kind string
@description('Specifies the location in which the Azure Storage Account resource(s) will be deployed.')
param location string
@description('Specifies the name of the Azure Storage Account.')
param name string
@description('An object that encapsulates the properties of the services that will be configured on the Azure Storage Account.')
param services object
@description('Specifies the SKU name of the Azure Storage Account.')
param skuName string

var default = {
    services: {
        blob: {
            containers: {
                collection: []
            }
            corsRules: []
            isAnonymousAccessEnabled: false
            isHierarchicalNamespaceEnabled: false
            isNetworkFileSystemV3Enabled: false
        }
        file: {
            corsRules: []
            shares: {
                collection: []
                isLargeSupportEnabled: false
            }
        }
    }
}
var servicesWithDefaults =union(default.services, services)
var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    kind: kind
    location: location
    name: name
    properties: {
        accessTier: accessTier
        allowBlobPublicAccess: servicesWithDefaults.blob.isAnonymousAccessEnabled
        allowSharedKeyAccess: isSharedKeyAccessEnabled
        defaultToOAuthAuthentication: true
        encryption: {
            keySource: 'Microsoft.Storage'
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
                    keyType: 'Account'
                }
                table: {
                    enabled: true
                    keyType: 'Account'
                }
            }
        }
        isHnsEnabled: servicesWithDefaults.blob.isHierarchicalNamespaceEnabled ? true : null
        isNfsV3Enabled: servicesWithDefaults.blob.isNetworkFileSystemV3Enabled ? true : null
        largeFileSharesState: servicesWithDefaults.file.shares.isLargeSupportEnabled ? 'Enabled' : 'Disabled'
        minimumTlsVersion: 'TLS1_2'
        networkAcls: {
            bypass: 'None'
            defaultAction: 'Allow'
        }
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        supportsHttpsTrafficOnly: isHttpsOnlyModeEnabled
    }
    sku: {
        name: skuName
    }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
    name: 'default'
    parent: storageAccount
    properties: {
        cors: {
            corsRules: servicesWithDefaults.blob.corsRules
        }
    }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for container in servicesWithDefaults.blob.containers.collection: {
    name: container.name
    parent: blobServices
    properties: union({
        metadata: union({ metadata: null }, container).metadata
        publicAccess: union({ publicAccessLevel: 'None' }, container).publicAccessLevel
    }, servicesWithDefaults.blob.isNetworkFileSystemV3Enabled ? {
        enableNfsV3AllSquash: union({ isNetworkFileSystemV3AllSquashEnabled: false }, container).isNetworkFileSystemV3AllSquashEnabled
        enableNfsV3RootSquash: union({ isNetworkFileSystemV3RootSquashEnabled: false }, container).isNetworkFileSystemV3RootSquashEnabled
    }: {})
}]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
    name: 'default'
    parent: storageAccount
    properties: {
        cors: {
            corsRules: servicesWithDefaults.file.corsRules
        }
    }
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = [for share in servicesWithDefaults.file.shares.collection: {
    name: share.name
    parent: fileServices
    properties: {
        accessTier: union({ accessTier: 'Hot' }, share).accessTier
        enabledProtocols: union({ enabledProtocols: 'SMB' }, share).enabledProtocols
        metadata: union({ metadata: null }, share).metadata
        rootSquash: (toUpper(union({ enabledProtocols: null }, share).enabledProtocols) == 'NFS') ? union({ rootSquashMode: 'NoRootSquash' }, share).rootSquashMode : null
        shareQuota: union({ quotaInGigabytes: 5 }, share).quotaInGigabytes
        signedIdentifiers: null
    }
}]
