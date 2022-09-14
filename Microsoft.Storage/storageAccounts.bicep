@description('Specifies the access tier of the Azure Storage Account.')
param accessTier string = 'Hot'
@description('An array of firewall rules that will be assigned to the Azure Storage Account.')
param firewallRules array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Storage Account.')
param identity object = {}
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Storage Account.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether HTTP network protocol support is restricted to HTTPS on the Azure Storage Account.')
param isHttpsOnlyModeEnabled bool = true
@description('Indicates whether the Azure Storage Account is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether shared keys are able to be used to access the Azure Storage Account.')
param isSharedKeyAccessEnabled bool = false
@description('Specifies the kind of the Azure Storage Account.')
param kind string = 'StorageV2'
@description('Specifies the location in which the Azure Storage Account resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Storage Account.')
param name string
@description('An object that encapsulates the properties of the services that will be configured on the Azure Storage Account.')
param services object = {}
@description('Specifies the SKU of the Azure Storage Account.')
param sku object = {
    name: 'Standard_LRS'
}
@description('An array of virtual network rules that will be assigned to the Azure Storage Account.')
param virtualNetworkRules array = []
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Storage Account.')
param tags object = {}

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
            bypass: isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None'
            defaultAction: (isPublicNetworkAccessEnabled && (empty(firewallRules) || empty(virtualNetworkRules))) ? 'Allow' : 'Deny'
            ipRules: [for rule in firewallRules: {
                action: 'Allow'
                value: rule
            }]
            virtualNetworkRules: [for rule in virtualNetworkRules: {
                action: 'Allow'
                id: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, rule.subnet).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetwork/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
            }]
        }
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        supportsHttpsTrafficOnly: isHttpsOnlyModeEnabled
    }
    sku: sku
    tags: tags
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
