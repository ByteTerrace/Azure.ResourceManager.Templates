@allowed([
    'Cool'
    'Hot'
])
param accessTier string = 'Hot'
@description('An object that encapsulates the audit settings that will be applied to the Azure Storage Account.')
param audit object = {}
@description('An array of firewall rules that will be assigned to the Azure Storage Account.')
param firewallRules array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Storage Account.')
param identity object = {}
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Storage Account.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the double-encryption at rest feature is enabled on the Azure Storage Account.')
param isDoubleEncryptionAtRestEnabled bool = true
@description('Indicates whether HTTP network protocol support is restricted to HTTPS on the Azure Storage Account.')
param isHttpsOnlyModeEnabled bool = true
@description('Indicates whether the Azure Storage Account is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether shared keys are able to be used to access the Azure Storage Account.')
param isSharedKeyAccessEnabled bool = false
@allowed([
    'BlobStorage'
    'BlockBlobStorage'
    'FileStorage'
    'Storage'
    'StorageV2'
])
@description('Specifies the kind of the Azure Storage Account.')
param kind string = 'StorageV2'
@description('Specifies the location in which the Azure Storage Account resource(s) will be deployed.')
param location string
@maxLength(24)
@minLength(3)
@description('Specifies the name of the Azure Storage Account.')
param name string
@description('An object that encapsulates the properties of the SAS policy that will be assigned to the Azure Storage Account.')
param sasPolicy object = {}
@description('')
param services object = {}
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
param skuName string = 'Standard_LRS'
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Storage Account.')
param tags object = {}
@description('An array of virtual network rules that will be assigned to the Azure Storage Account.')
param virtualNetworkRules array = []

var defaults = {
    audit: {
        logAnalyticsWorkspace: {}
        logs: []
        metrics: []
        storageAccount: {}
    }
    container: {
        isNetworkFileSystemV3AllSquashEnabled: false
        isNetworkFileSystemV3RootSquashEnabled: false
        metadata: null
        publicAccessLevel: 'None'
        versioning: {
            immutability: {
                isEnabled: false
                isProtectedAppendWritesEnabled: false
                retentionPeriodInDays: 3
            }
            isEnabled: false
        }
    }
    queue: {
        metadata: null
    }
    services: {
        blob: {
            audit: {
                logAnalyticsWorkspace: {}
                logs: []
                metrics: []
                storageAccount: {}
            }
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
            }
            isAnonymousAccessEnabled: false
            isHierarchicalNamespaceEnabled: false
            isNetworkFileSystemV3Enabled: false
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
            versioning: {
                immutability: {
                    isEnabled: false
                    isProtectedAppendWritesEnabled: false
                    retentionPeriodInDays: 3
                    state: 'Disabled'
                }
                isEnabled: false
            }
        }
        file: {
            audit: {
                logAnalyticsWorkspace: {}
                logs: []
                metrics: []
                storageAccount: {}
            }
            corsRules: []
            encryption: {
                isEnabled: true
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
            audit: {
                logAnalyticsWorkspace: {}
                logs: []
                metrics: []
                storageAccount: {}
            }
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
        }
        table: {
            audit: {
                logAnalyticsWorkspace: {}
                logs: []
                metrics: []
                storageAccount: {}
            }
            corsRules: []
            encryption: {
                isEnabled: true
                keyType: 'Account'
            }
        }
    }
    share: {
        accessTier: 'Hot'
        enabledProtocols: 'SMB'
        metadata: null
        quotaInGigabytes: 5
        rootSquashMode: 'NoRootSquash'
    }
}
var auditWithDefaults = union(defaults.audit, audit)
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
        azureFilesIdentityBasedAuthentication: null
        customDomain: null
        defaultToOAuthAuthentication: true
        encryption: {
            identity: null
            keySource: 'Microsoft.Storage'
            keyvaultproperties: null
            requireInfrastructureEncryption: isDoubleEncryptionAtRestEnabled
            services: {
                blob: {
                    enabled: servicesWithDefaults.blob.encryption.isEnabled
                    keyType: 'Account'
                }
                file: {
                    enabled: servicesWithDefaults.file.encryption.isEnabled
                    keyType: 'Account'
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
        immutableStorageWithVersioning: (servicesWithDefaults.blob.versioning.isEnabled ? {
            enabled : servicesWithDefaults.blob.versioning.immutability.isEnabled
            immutabilityPolicy: (servicesWithDefaults.blob.versioning.immutability.isEnabled ? {
                allowProtectedAppendWrites: servicesWithDefaults.blob.versioning.immutability.isProtectedAppendWritesEnabled
                immutabilityPeriodSinceCreationInDays: servicesWithDefaults.blob.versioning.immutability.retentionPeriodInDays
                state: servicesWithDefaults.blob.versioning.immutability.state
            } : null)
        } : null)
        isHnsEnabled: (servicesWithDefaults.blob.isHierarchicalNamespaceEnabled ? true : null)
        isLocalUserEnabled: servicesWithDefaults.blob.sftp.isLocalUserAccessEnabled
        isNfsV3Enabled: (servicesWithDefaults.blob.isNetworkFileSystemV3Enabled ? true : null)
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

resource storageAccountDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(auditWithDefaults.storageAccount) && empty(auditWithDefaults.logAnalyticsWorkspace))) {
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, auditWithDefaults.logAnalyticsWorkspace).destinationType
        logs: [for log in auditWithDefaults.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in auditWithDefaults.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(auditWithDefaults.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, auditWithDefaults.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', auditWithDefaults.storageAccount.name))
        workspaceId: (empty(auditWithDefaults.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, auditWithDefaults.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', auditWithDefaults.logAnalyticsWorkspace.name))
    }
    scope: storageAccount
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
        isVersioningEnabled: servicesWithDefaults.blob.versioning.isEnabled
        lastAccessTimeTrackingPolicy: null
        restorePolicy: {
            days: servicesWithDefaults.blob.pointInTimeRestoration.retentionPeriodInDays
            enabled: servicesWithDefaults.blob.pointInTimeRestoration.isEnabled
        }
    }
}

resource blobDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(servicesWithDefaults.blob.audit.storageAccount) && empty(servicesWithDefaults.blob.audit.logAnalyticsWorkspace))) {
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, servicesWithDefaults.blob.audit.logAnalyticsWorkspace).destinationType
        logs: [for log in servicesWithDefaults.blob.audit.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in servicesWithDefaults.blob.audit.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(servicesWithDefaults.blob.audit.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.blob.audit.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', servicesWithDefaults.blob.audit.storageAccount.name))
        workspaceId: (empty(servicesWithDefaults.blob.audit.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.blob.audit.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', servicesWithDefaults.blob.audit.logAnalyticsWorkspace.name))
    }
    scope: blobServices
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = [for container in servicesWithDefaults.blob.containers.collection: {
    dependsOn: [
        blobServices
    ]
    name: '${name}/default/${container.name}'
    properties: union({
        defaultEncryptionScope: null
        denyEncryptionScopeOverride: null
        metadata: union(defaults.container, container).metadata
        publicAccess: union(defaults.container, container).publicAccessLevel
    }, (servicesWithDefaults.blob.isNetworkFileSystemV3Enabled ? {
        enableNfsV3AllSquash: union(defaults.container, container).isNetworkFileSystemV3AllSquashEnabled
        enableNfsV3RootSquash: union(defaults.container, container).isNetworkFileSystemV3RootSquashEnabled
    }: {}), (union(defaults.container, container).versioning.isEnabled ? {
        immutableStorageWithVersioning: {
            enabled: union(defaults.container, container).versioning.immutability.isEnabled
        }
    }: {}))
}]

resource blobContainersImmutabilityPolicies 'Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies@2021-08-01' = [for container in servicesWithDefaults.blob.containers.collection: if(union(defaults.container, container).versioning.immutability.isEnabled) {
    dependsOn: [
        blobContainers
        blobServices
    ]
    name: '${name}/default/${container.name}/default'
    properties: {
        allowProtectedAppendWrites: union(defaults.container, container).versioning.immutability.isProtectedAppendWritesEnabled
        immutabilityPeriodSinceCreationInDays: union(defaults.container, container).versioning.immutability.retentionPeriodInDays
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

resource fileDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(servicesWithDefaults.file.audit.storageAccount) && empty(servicesWithDefaults.file.audit.logAnalyticsWorkspace))) {
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, servicesWithDefaults.file.audit.logAnalyticsWorkspace).destinationType
        logs: [for log in servicesWithDefaults.file.audit.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in servicesWithDefaults.file.audit.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(servicesWithDefaults.file.audit.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.file.audit.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', servicesWithDefaults.file.audit.storageAccount.name))
        workspaceId: (empty(servicesWithDefaults.file.audit.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.file.audit.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', servicesWithDefaults.file.audit.logAnalyticsWorkspace.name))
    }
    scope: fileServices
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = [for share in servicesWithDefaults.file.shares.collection: {
    dependsOn: [
        fileServices
    ]
    name: '${name}/default/${share.name}'
    properties: {
        accessTier: union(defaults.share, share).accessTier
        enabledProtocols: union(defaults.share, share).enabledProtocols
        metadata: union(defaults.share, share).metadata
        rootSquash: ((toLower(union(defaults.share, share).enabledProtocols) == 'NFS') ? union(defaults.share, share).rootSquashMode : null)
        shareQuota: union(defaults.share, share).quotaInGigabytes
        signedIdentifiers: null
    }
}]

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

resource queueDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(servicesWithDefaults.queue.audit.storageAccount) && empty(servicesWithDefaults.queue.audit.logAnalyticsWorkspace))) {
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, servicesWithDefaults.queue.audit.logAnalyticsWorkspace).destinationType
        logs: [for log in servicesWithDefaults.queue.audit.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in servicesWithDefaults.queue.audit.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(servicesWithDefaults.queue.audit.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.queue.audit.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', servicesWithDefaults.queue.audit.storageAccount.name))
        workspaceId: (empty(servicesWithDefaults.queue.audit.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.queue.audit.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', servicesWithDefaults.queue.audit.logAnalyticsWorkspace.name))
    }
    scope: queueServices
}

resource queues 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = [for queue in servicesWithDefaults.queue.collection: {
    dependsOn: [
        queueServices
    ]
    name: '${name}/default/${queue.name}'
    properties: {
        metadata: union(defaults.queue, queue).metadata
    }
}]

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

resource tableDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(servicesWithDefaults.table.audit.storageAccount) && empty(servicesWithDefaults.table.audit.logAnalyticsWorkspace))) {
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, servicesWithDefaults.table.audit.logAnalyticsWorkspace).destinationType
        logs: [for log in servicesWithDefaults.table.audit.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in servicesWithDefaults.table.audit.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(servicesWithDefaults.table.audit.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.table.audit.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', servicesWithDefaults.table.audit.storageAccount.name))
        workspaceId: (empty(servicesWithDefaults.table.audit.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicesWithDefaults.table.audit.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', servicesWithDefaults.table.audit.logAnalyticsWorkspace.name))
    }
    scope: tableServices
}

resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-08-01' = [for table in servicesWithDefaults.table.collection: {
    dependsOn: [
        tableServices
    ]
    name: '${name}/default/${table.name}'
}]
