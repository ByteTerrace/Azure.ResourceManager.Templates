@allowed([
    'Cool'
    'Hot'
])
param accessTier string
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Storage Account.')
param firewallRules array
@description('An array of firewall rules that will be assigned to the Azure Storage Account.')
param identity object
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Storage Account.')
param isAllowTrustedMicrosoftServicesEnabled bool
@description('Indicates whether the double-encryption at rest feature is enabled on the Azure Disk Encryption Set.')
param isDoubleEncryptionAtRestEnabled bool
@description('Indicates whether HTTP network protocol support is restricted to HTTPS on the Azure Storage Account.')
param isHttpsOnlyModeEnabled bool
@description('Indicates whether the Azure Storage Account is accessible from the internet.')
param isPublicNetworkAccessEnabled bool
@description('Indicates whether shared keys are able to be used to access the Azure Storage Account.')
param isSharedKeyAccessEnabled bool
@allowed([
    'BlobStorage'
    'BlockBlobStorage'
    'FileStorage'
    'Storage'
    'StorageV2'
])
@description('Specifies the kind of the Azure Storage Account.')
param kind string
@description('Specifies the location in which the Azure Storage Account resource(s) will be deployed.')
param location string
@maxLength(24)
@minLength(3)
@description('Specifies the name of the Azure Storage Account.')
param name string
@description('An object that encapsulates the properties of the SAS policy that will be assigned to the Azure Storage Account.')
param sasPolicy object
@description('')
param services object
@allowed([
    'Premium_LRS'
    'Premium_ZRS'
    'Standard_GRS'
    'Standard_GZRS'
    'Standard_LRS'
    'Standard_RAGRS'
    'Standard_RAGZRS'
    'Standard_ZRS'
])
@description('Specifies the SKU name of the Azure Storage Account.')
param skuName string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Storage Account.')
param tags object
@description('An array of virtual network rules that will be assigned to the Azure Storage Account.')
param virtualNetworkRules array

var defaults = {
    container: {
        isNetworkFileSystemV3AllSquashEnabled: false
        isNetworkFileSystemV3RootSquashEnabled: false
        metadata: null
        publicAccessLevel: 'None'
    }
    services: {
        blob: {
            changeFeed: {
                isEnabled: false
                retentionPeriodInDays: 3
            }
            containers: {
                collection: []
                softDeletion: {
                    isEnabled: true
                    retentionPeriodInDays: 13
                }
            }
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
            isAnonymousAccessEnabled: false
            isHierarchicalNamespaceEnabled: false
            isNetworkFileSystemV3Enabled: false
            isVersioningEnabled: false
            pointInTimeRestoration: {
                isEnabled: false
                retentionPeriodInDays: 3
            }
            sftp: {
                isEnabled: false
                isLocalUserAccessEnabled: false
            }
            softDeletion: {
                isEnabled: true
                retentionPeriodInDays: 13
            }
        }
        file: {
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
            serverMessageBlock: {
                authenticationMethods: 'Kerberos;'
                channelEncryption: 'AES-256-GCM;'
                kerberosTicketEncryption: 'AES-256;'
                versions: 'SMB3.1.1;'
            }
            shares: {
                collection: []
                isLargeSupportEnabled: false
                softDeletion: {
                    isEnabled: true
                    retentionPeriodInDays: 7
                }
            }
        }
        queue: {
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
        }
        table: {
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
        }
    }
}
var servicesWithDefaults = union(defaults.services, services)
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: resourceId(union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName, 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
    identity: {
        type: union({
            type: (empty(userAssignedIdentities) ? 'None' : 'UserAssigned')
        }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    kind: kind
    location: location
    name: name
    properties: {
        accessTier: ((toLower(kind) == 'storage') ? null : accessTier)
        allowBlobPublicAccess: servicesWithDefaults.blob.isAnonymousAccessEnabled
        allowCrossTenantReplication: null
        allowedCopyScope: null
        allowSharedKeyAccess: isSharedKeyAccessEnabled
        defaultToOAuthAuthentication: true
        encryption: {
            identity: null
            keySource: 'Microsoft.Storage'
            keyvaultproperties: null
            requireInfrastructureEncryption: isDoubleEncryptionAtRestEnabled
            services: {
                blob: {
                    enabled: servicesWithDefaults.blob.encryption.isEnabled
                    keyType: servicesWithDefaults.blob.encryption.keyType
                }
                file: {
                    enabled: servicesWithDefaults.file.encryption.isEnabled
                    keyType: servicesWithDefaults.file.encryption.keyType
                }
                queue: {
                    enabled: servicesWithDefaults.queue.encryption.isEnabled
                    keyType: servicesWithDefaults.queue.encryption.keyType
                }
                table: {
                    enabled: servicesWithDefaults.table.encryption.isEnabled
                    keyType: servicesWithDefaults.table.encryption.keyType
                }
            }
        }
        isHnsEnabled: (servicesWithDefaults.blob.isHierarchicalNamespaceEnabled ? true : bool(null))
        isLocalUserEnabled: servicesWithDefaults.blob.sftp.isLocalUserAccessEnabled
        isNfsV3Enabled: (servicesWithDefaults.blob.isNetworkFileSystemV3Enabled ? true : bool(null))
        isSftpEnabled: servicesWithDefaults.blob.sftp.isEnabled
        keyPolicy: null
        largeFileSharesState: (servicesWithDefaults.file.shares.isLargeSupportEnabled ? 'Enabled' : 'Disabled')
        minimumTlsVersion: 'TLS1_2'
        networkAcls: {
            bypass: (isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None')
            defaultAction: (isPublicNetworkAccessEnabled ? 'Allow' : 'Deny')
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
                }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
            }]
        }
        publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled': 'Disabled')
        routingPreference: null
        sasPolicy: (empty(sasPolicy) ? null : sasPolicy)
        supportsHttpsTrafficOnly: isHttpsOnlyModeEnabled
    }
    sku: {
        name: skuName
    }
    tags: tags
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
    dependsOn: [
        storageAccount
    ]
    name: '${name}/default'
    properties: {
        changeFeed: {
            enabled: servicesWithDefaults.blob.changeFeed.isEnabled
            retentionInDays: (servicesWithDefaults.blob.changeFeed.isEnabled ? servicesWithDefaults.blob.changeFeed.retentionPeriodInDays : null)
        }
        containerDeleteRetentionPolicy: {
            days: servicesWithDefaults.blob.containers.softDeletion.retentionPeriodInDays
            enabled: servicesWithDefaults.blob.containers.softDeletion.isEnabled
        }
        cors: {
            corsRules: servicesWithDefaults.blob.corsRules
        }
        deleteRetentionPolicy: {
            days: servicesWithDefaults.blob.softDeletion.retentionPeriodInDays
            enabled: servicesWithDefaults.blob.softDeletion.isEnabled
        }
        isVersioningEnabled: servicesWithDefaults.blob.isVersioningEnabled
        restorePolicy: {
            days: servicesWithDefaults.blob.pointInTimeRestoration.retentionPeriodInDays
            enabled: servicesWithDefaults.blob.pointInTimeRestoration.isEnabled
        }
    }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = [for container in servicesWithDefaults.blob.containers.collection: {
    dependsOn: [
        blobServices
    ]
    name: '${name}/default/${container.name}'
    properties: {
        defaultEncryptionScope: null
        denyEncryptionScopeOverride: null
        enableNfsV3AllSquash: union(defaults.container, container).isNetworkFileSystemV3AllSquashEnabled
        enableNfsV3RootSquash: union(defaults.container, container).isNetworkFileSystemV3RootSquashEnabled
        immutableStorageWithVersioning: null
        metadata: union(defaults.container, container).metadata
        publicAccess: union(defaults.container, container).publicAccessLevel
    }
}]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
    dependsOn: [
        storageAccount
    ]
    name: '${name}/default'
    properties: {
        cors: {
            corsRules: servicesWithDefaults.file.corsRules
        }
        protocolSettings: {
            smb: {
                authenticationMethods: servicesWithDefaults.file.serverMessageBlock.authenticationMethods
                channelEncryption: servicesWithDefaults.file.serverMessageBlock.channelEncryption
                kerberosTicketEncryption: servicesWithDefaults.file.serverMessageBlock.kerberosTicketEncryption
                versions: servicesWithDefaults.file.serverMessageBlock.versions
            }
        }
        shareDeleteRetentionPolicy: {
            days: servicesWithDefaults.file.shares.softDeletion.retentionPeriodInDays
            enabled: servicesWithDefaults.file.shares.softDeletion.isEnabled
        }
    }
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-08-01' = {
    dependsOn: [
        storageAccount
    ]
    name: '${name}/default'
    properties: {
        cors: {
            corsRules: servicesWithDefaults.queue.corsRules
        }
    }
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2021-08-01' = {
    dependsOn: [
        storageAccount
    ]
    name: '${name}/default'
    properties: {
        cors: {
            corsRules: servicesWithDefaults.table.corsRules
        }
    }
}
