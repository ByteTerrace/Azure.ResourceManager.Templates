param location string = 'West US 3'
param projectName string = 'tlk'
param overrides object = {
    excludedTypes: [
        'microsoft.network/application-gateways'
    ]
    includedTypes: []
}

// variables
var excludedTypes = [for type in overrides.excludedTypes: toLower(type)]
var includedTypes = [for type in empty(overrides.includedTypes) ? [
    'microsoft.app-configuration/configuration-stores'
    'microsoft.authorization/role-assignments'
    'microsoft.cdn/profiles'
    'microsoft.compute/availability-sets'
    'microsoft.compute/disk-encryption-sets'
    'microsoft.compute/proximity-placement-groups'
    'microsoft.compute/virtual-machines'
    'microsoft.container-registry/registries'
    'microsoft.insights/components'
    'microsoft.key-vault/vaults'
    'microsoft.machine-learning-services/workspaces'
    'microsoft.managed-identity/user-assigned-identities'
    'microsoft.network/application-gateways'
    'microsoft.network/application-security-groups'
    'microsoft.network/dns-zones'
    'microsoft.network/nat-gateways'
    'microsoft.network/network-interfaces'
    'microsoft.network/network-security-groups'
    'microsoft.network/private-dns-zones'
    'microsoft.network/private-endpoints'
    'microsoft.network/public-ip-addresses'
    'microsoft.network/public-ip-prefixes'
    'microsoft.network/virtual-network-gateways'
    'microsoft.network/virtual-networks'
    'microsoft.operational-insights/workspaces'
    'microsoft.resources/deployments'
    'microsoft.service-bus/namespaces'
    'microsoft.signalr-service/signalr'
    'microsoft.sql/servers'
    'microsoft.storage/storage-accounts'
    'microsoft.web/server-farms'
    'microsoft.web/sites'
] : overrides.includedTypes: toLower(type)]

// resource definitions
var applicationConfigurationStores = [
    {
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isPublicNetworkAccessEnabled: true
        isPurgeProtectionEnabled: false
        settings: {
            'The:Password': {
                keyVault: {
                    name: 'tlk-kv-00000'
                    secretName: 'The-Password'
                }
            }
            Version: {
                value: '1.0.0'
            }
        }
        sku: {
            name: 'Free'
        }
    }
]
var applicationGateways = [
    {
        availabilityZones: []
        backendAddressPools: [
            {
              name: 'default'
            }
        ]
        backendHttpSettings: [
            {
                name: 'default'
                port: 80
                protocol: 'Http'
            }
        ]
        frontEnd: {
            ports: [
                80
            ]
            privateIpAddress: {
                value: '10.255.1.4'
            }
            publicIpAddress: {
                name: 'tlk-pip-00002'
            }
        }
        httpListeners: [
            {
                hostName: 'thelankrew.com'
                name: 'default'
                port: 80
                protocol: 'Http'
            }
        ]
        identity: {
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        routingRules: [
            {
                backendAddressPoolName: 'default'
                backendHttpSettingsCollectionName: 'default'
                httpListenerName: 'default'
                name: 'default'
            }
        ]
        sku: {
            capacity: 1
            name: 'Standard_v2'
            tier: 'Standard_v2'
        }
        subnet: {
            name: 'tlk-snet-00002'
            virtualNetworkName: 'tlk-vnet-00000'
        }
    }
]
var applicationInsights = [
    {
        logAnalyticsWorkspace: {
            name: 'tlk-law-00000'
        }
    }
]
var applicationSecurityGroups = [
    {}
]
var applicationServicePlans = [
    {
        isZoneRedundancyEnabled: false
        sku: {
            name: 'Y1'
        }
    }
    {
        isZoneRedundancyEnabled: false
        sku: {
            name: 'F1'
        }
    }
]
var availabilitySets = [
    {
        proximityPlacementGroup: {
            name: 'tlk-ppg-00000'
        }
        numberOfFaultDomains: 3
        numberOfUpdateDomains: 5
        sku: {
            name: 'Aligned'
        }
    }
]
var cdnProfiles = [
    {
        name: 'byteterrace'
        resourceGroupName: 'byteterrace'
        sku: {
            name: 'Standard_AzureFrontDoor'
        }
    }
]
var containerRegistries = [
    {
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isPublicNetworkAccessEnabled: true
        isZoneRedundancyEnabled: false
        sku: {
            name: 'Basic'
        }
    }
]
var deployments = []
var diskEncryptionSets = [
    {
        identity: {
            type: 'SystemAssigned'
        }
        keyName: 'VirtualMachine-Disk-Encryption'
        keyVault: {
            name: 'tlk-kv-00000'
        }
    }
]
var keyVaults = [
    {
        isAllowTrustedMicrosoftServicesEnabled: true
        isPublicNetworkAccessEnabled: false
        isPurgeProtectionEnabled: true
        isRbacAuthorizationEnabled: true
        isTemplateDeploymentEnabled: true
        keys: {
            'VirtualMachine-Disk-Encryption': {
                allowedOperations: []
                rotationPolicy: {
                    expiryTime: 'P1Y'
                    isAutomaticRotationEnabled: true
                    rotationTime: 'P6M'
                }
                size: 2048
                type: 'RSA'
            }
        }
        secrets: {
            'The-Password': {
                value: 'It\'s a secret to everybody!'
            }
        }
        sku: {
            name: 'premium'
        }
    }
]
var logAnalyticsWorkspaces = [
    {
        isPublicNetworkAccessForIngestionEnabled: true
        isPublicNetworkAccessForQueryEnabled: true
    }
]
var machineLearningWorkspaces = [
    {
        applicationInsights: {
            name: 'tlk-ai-00000'
        }
        containerRegistry: {
            name: 'tlkcr00000'
        }
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isPublicNetworkAccessEnabled: false
        keyVault: {
            name: 'tlk-kv-00000'
        }
        sku: {
            name: 'Basic'
        }
        storageAccount: {
            name: 'tlkdata00000'
        }
    }
]
var natGateways = [
    {
        publicIpAddresses: [
            {
                name: 'tlk-pip-00001'
            }
        ]
    }
]
var networkInterfaces = [
    {
        ipConfigurations: [
                {
                    name: 'Ipv4config'
                    privateIpAddress: {
                        value: '10.255.0.4'
                    }
                    subnet: {
                        name: 'tlk-snet-00000'
                        virtualNetworkName: 'tlk-vnet-00000'
                    }
                }
        ]
        isAcceleratedNetworkingEnabled: false
        isIpForwardingEnabled: false
    }
]
var networkSecurityGroups = [
    {
        securityRules: [
            {
                access: 'Allow'
                destination: {
                    addressPrefixes: [ '10.255.0.0/16' ]
                    ports: [ '3389', '443' ]
                }
                direction: 'Inbound'
                name: 'Allow-Inbound-Default'
                protocol: '*'
                source: {
                    addressPrefixes: [ '47.188.32.200' ]
                    ports: [ '*' ]
                }
            }
        ]
    }
]
var privateDnsZones = [
    {
        name: 'privatelink.web.${environment().suffixes.storage}'
        virtualNetworkLinks: [
            {
                virtualNetwork: {
                    name: 'tlk-vnet-00000'
                }
            }
        ]
    }
]
var privateEndpoints = [
    {
        name: 'tlk-kv-00000_tlk-vnet-00000_tlk-snet-00000'
        resource: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        subnet: {
            name: 'tlk-snet-00000'
            virtualNetworkName: 'tlk-vnet-00000'
        }
    }
    {
        name: 'tlkdata00000-blobs_tlk-vnet-00000_tlk-snet-00000'
        resource: {
            name: 'tlkdata00000/blobServices'
            type: 'Microsoft.Storage/storageAccounts'
        }
        subnet: {
            name: 'tlk-snet-00000'
            virtualNetworkName: 'tlk-vnet-00000'
        }
    }
    {
        name: 'tlkdata00000-web_tlk-vnet-00000_tlk-snet-00000'
        resource: {
            name: 'tlkdata00000/staticWebsite'
            type: 'Microsoft.Storage/storageAccounts'
        }
        subnet: {
            name: 'tlk-snet-00000'
            virtualNetworkName: 'tlk-vnet-00000'
        }
    }
]
var proximityPlacementGroups = [
    {}
]
var publicDnsZones = [
    {
        cnameRecords: [
            {
                alias: 'default-dnfngvbjg9ckaddn.z01.azurefd.net'
                name: 'data'
                timeToLiveInSeconds: 3600
            }
        ]
        name: 'thelankrew.com'
    }
]
var publicIpAddresses = [
    {
        allocationMethod: 'Dynamic'
        sku: {
            name: 'Basic'
        }
        skuTier: 'Regional'
    }
    {
        allocationMethod: 'Static'
        sku: {
            name: 'Standard'
        }
        skuTier: 'Regional'
    }
]
var publicIpPrefixes = []
var roleAssignments = [
    {
        assignee: {
            name: 'tlkdata00000'
            type: 'Microsoft.Storage/storageAccounts'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Crypto Service Encryption User'
    }
    {
        assignee: {
            name: 'tlk-acs-00000'
            type: 'Microsoft.AppConfiguration/configurationStores'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Secrets User'
    }
    {
        assignee: {
            name: 'tlk-des-00000'
            type: 'Microsoft.Compute/diskEncryptionSets'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Crypto Service Encryption User'
    }
    {
        assignee: {
            name: 'tlk-mi-00000'
            type: 'Microsoft.ManagedIdentity/userAssignedIdentities'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Crypto Service Encryption User'
    }
    {
        assignee: {
            name: 'tlk-sql-00000'
            type: 'Microsoft.Sql/servers'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Crypto Service Encryption User'
    }
    {
        assignee: {
            name: 'tlk-web-00000'
            type: 'Microsoft.Web/sites'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Secrets User'
    }
    {
        assignee: {
            name: 'tlk-web-00001'
            type: 'Microsoft.Web/sites'
        }
        assignor: {
            name: 'tlk-kv-00000'
            type: 'Microsoft.KeyVault/vaults'
        }
        roleDefinitionName: 'Key Vault Secrets User'
    }
    {
        assignee: {
            name: 'tlk-web-00000'
            type: 'Microsoft.Web/sites'
        }
        assignor: {
            name: 'tlk-acs-00000'
            type: 'Microsoft.AppConfiguration/configurationStores'
        }
        roleDefinitionName: 'App Configuration Data Reader'
    }
    {
        assignee: {
            name: 'tlk-web-00001'
            type: 'Microsoft.Web/sites'
        }
        assignor: {
            name: 'tlk-acs-00000'
            type: 'Microsoft.AppConfiguration/configurationStores'
        }
        roleDefinitionName: 'App Configuration Data Reader'
    }
]
var serviceBusNamespaces = [
    {
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isPublicNetworkAccessEnabled: true
        isZoneRedundancyEnabled: false
        sku: {
            name: 'Basic'
        }
    }
]
var signalrServices = [
    {
        identity: {
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isPublicNetworkAccessEnabled: false
        isSharedKeyAccessEnabled: false
        sku: {
            name: 'Free_F1'
        }
    }
]
var sqlServers = [
    {
        administrator: {
            login: 'administrator@byteterrace.com'
            objectId: '84e6e9e4-e3d8-4484-ab7f-a77014fd182e'
        }
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isAllowTrustedMicrosoftServicesEnabled: false
        isPublicNetworkAccessEnabled: false
    }
]
var storageAccounts = [
    {
        accessTier: 'Hot'
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        isAllowTrustedMicrosoftServicesEnabled: false
        isHttpsOnlyModeEnabled: true
        isPublicNetworkAccessEnabled: true
        isSharedKeyAccessEnabled: true
        kind: 'StorageV2'
        services: {
            blob: {
                containers: {
                    collection: [
                        {
                            name: 'binaries'
                            publicAccessLevel: 'Container'
                        }
                        {
                            name: '$web'
                            publicAccessLevel: 'None'
                        }
                    ]
                }
                isAnonymousAccessEnabled: true
                isHierarchicalNamespaceEnabled: false
                isNetworkFileSystemV3Enabled: false
            }
        }
        sku: {
            name: 'Standard_LRS'
        }
    }
]
var userAssignedIdentities = [
    {}
]
var virtualMachines = [
    {
        administrator: {
            password: 'It\'s a secret to everybody!'
            userName: 'TheWindfish'
        }
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        imageReference: {
            offer: 'UbuntuServer'
            publisher: 'Canonical'
            sku: '18_04-lts-gen2'
            version: 'latest'
        }
        linuxConfiguration: {
            isVmAgentEnabled: true
        }
        networkInterfaces: [
            {
                name: 'tlk-nic-00000'
            }
        ]
        proximityPlacementGroup: {
            name: 'tlk-ppg-00000'
        }
        sku: {
            name: 'Standard_B1ms'
        }
    }
]
var virtualNetworkGateways = [
    {
        clientConfiguration: {
            addressPrefixes: [ '172.23.0.0/24' ]
            authenticationTypes: [ 'Certificate' ]
            protocols: [ 'SSTP' ]
            rootCertificates: [
                {
                    name: 'tlk-root-ca'
                    publicCertificateData: 'MIIDMzCCAtigAwIBAgICEAAwCgYIKoZIzj0EAwIwfjELMAkGA1UEBhMCVVMxGTAXBgNVBAoMEFRoZSBMQU4gS3JldyBMTEMxIjAgBgNVBAsMGVB1YmxpYyBLZXkgSW5mcmFzdHJ1Y3R1cmUxMDAuBgNVBAMMJ1RoZSBMQU4gS3JldyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0yMDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMH4xCzAJBgNVBAYTAlVTMRkwFwYDVQQKDBBUaGUgTEFOIEtyZXcgTExDMSIwIAYDVQQLDBlQdWJsaWMgS2V5IEluZnJhc3RydWN0dXJlMTAwLgYDVQQDDCdUaGUgTEFOIEtyZXcgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATcO35AnKj2itLrBYDDNFk8SByRf9ucM7cPdAR+bAqzmW+wSMYlIZOsZ50BabEt+aIpj/QndMJnltcFpQSwLpQPo4IBRDCCAUAwHQYDVR0OBBYEFIIMdrwm7VbwIDgVSiMVmI1Lzsq2MIGrBgNVHSMEgaMwgaCAFIIMdrwm7VbwIDgVSiMVmI1Lzsq2oYGDpIGAMH4xCzAJBgNVBAYTAlVTMRkwFwYDVQQKDBBUaGUgTEFOIEtyZXcgTExDMSIwIAYDVQQLDBlQdWJsaWMgS2V5IEluZnJhc3RydWN0dXJlMTAwLgYDVQQDDCdUaGUgTEFOIEtyZXcgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCAhAAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMFAGA1UdEQRJMEeCDnRoZWxhbmtyZXcuY29tgR1hZG1pbmlzdHJhdG9yQGJ5dGV0ZXJyYWNlLmNvbYYWaHR0cHM6Ly90aGVsYW5rcmV3LmNvbTAKBggqhkjOPQQDAgNJADBGAiEA85JqQ+/YYjYN3iWef5FfeXiXPMZmoVULtWQARg1Lu38CIQCNK7Gb2cbBtCrlkmJYzGNHSREuugV6WEj6Q+Hwmte39Q=='
                }
                {
                    name: 'tlk-virtual-network-ca'
                    publicCertificateData: 'MIICsTCCAligAwIBAgICEAEwCgYIKoZIzj0EAwIwfjELMAkGA1UEBhMCVVMxGTAXBgNVBAoMEFRoZSBMQU4gS3JldyBMTEMxIjAgBgNVBAsMGVB1YmxpYyBLZXkgSW5mcmFzdHJ1Y3R1cmUxMDAuBgNVBAMMJ1RoZSBMQU4gS3JldyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0yMDAxMDEwMDAwMDBaFw0zODAxMTkwMzE0MDdaMIGJMQswCQYDVQQGEwJVUzEZMBcGA1UECgwQVGhlIExBTiBLcmV3IExMQzEiMCAGA1UECwwZUHVibGljIEtleSBJbmZyYXN0cnVjdHVyZTE7MDkGA1UEAwwyVGhlIExBTiBLcmV3IFZpcnR1YWwgTmV0d29yayBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATOGWzhyqmnD+FhihnXEFGDrY0Jn+fmDrhedyqSnT+AS6TOwTOa3zYrSCNkAtr/nCO04qEns/xajnEM0/nmE5x0o4G5MIG2MB0GA1UdDgQWBBQLtNqhS4EG2cL4QckPvnoJr8c+wTAfBgNVHSMEGDAWgBSCDHa8Ju1W8CA4FUojFZiNS87KtjASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBBjBQBgNVHREESTBHgg50aGVsYW5rcmV3LmNvbYEdYWRtaW5pc3RyYXRvckBieXRldGVycmFjZS5jb22GFmh0dHBzOi8vdGhlbGFua3Jldy5jb20wCgYIKoZIzj0EAwIDRwAwRAIgMuUOpCyV5hiEHWtwx20X7+ywamBYlukoBGcHskd8QRECIGnUyBNSRF5bwKBF0kOG9qSzYxZLfwQtJQ+0XCa4e1ot'
                }
            ]
        }
        generation: 1
        ipConfigurations: [
            {
                publicIpAddress: {
                    name: 'tlk-pip-00000'
                }
                subnet: {
                    virtualNetworkName: 'tlk-vnet-00000'
                }
            }
        ]
        isActiveActiveModeEnabled: false
        mode: 'RouteBased'
        sku: {
            name: 'Basic'
        }
        type: 'Vpn'
    }
]
var virtualNetworks = [
    {
        addressPrefixes: [ '10.255.0.0/16' ]
        dnsServers: [ '10.255.0.4' ]
        subnets: [
            {
                addressPrefixes: [ '10.255.137.0/26' ]
                isPrivateEndpointNetworkPoliciesEnabled: true
                isPrivateLinkServiceNetworkPoliciesEnabled: true
                name: 'GatewaySubnet'
            }
            {
                addressPrefixes: [ '10.255.0.0/25' ]
                isPrivateEndpointNetworkPoliciesEnabled: true
                isPrivateLinkServiceNetworkPoliciesEnabled: true
                name: 'tlk-snet-00000'
                natGateway: {
                    name: 'tlk-nat-00000'
                }
                networkSecurityGroup: {
                    name: 'tlk-nsg-00000'
                }
            }
        ]
    }
]
var webApplications = [
    {
        applicationInsights: {
            name: 'tlk-ai-00000'
        }
        applicationSettings: {
            FUNCTIONS_EXTENSION_VERSION: '~4'
            FUNCTIONS_WORKER_RUNTIME: 'dotnet'
            WEBSITE_CONTENTSHARE: 'tlk-fun-00000839a'
        }
        functionExtension: {
            storageAccount: {
                name: 'tlkdata00000'
            }
        }
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        servicePlan: {
            name: 'tlk-asp-00000'
        }
    }
    {
        applicationInsights: {
            name: 'tlk-ai-00000'
        }
        applicationSettings: {
            ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
            XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
        }
        identity: {
            type: 'SystemAssigned,UserAssigned'
            userAssignedIdentities: [
                {
                    name: 'tlk-mi-00000'
                }
            ]
        }
        is32BitModeEnabled: true
        servicePlan: {
            name: 'tlk-asp-00001'
        }
    }
]

// module imports
module applicationConfigurationStoresCopy 'br/tlk:microsoft.app-configuration/configuration-stores:1.0.0' = [for (store, index) in applicationConfigurationStores: if (contains(includedTypes, 'microsoft.app-configuration/configuration-stores') && !contains(excludedTypes, 'microsoft.app-configuration/configuration-stores')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-acs-${string(index)}'
    params: {
        identity: union({ identity: {} }, store).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, store).isPublicNetworkAccessEnabled
        isPurgeProtectionEnabled: union({ isPurgeProtectionEnabled: true }, store).isPurgeProtectionEnabled
        location: union({ location: location }, store).location
        name: union({ name: '${projectName}-acs-${padLeft(index, 5, '0')}' }, store).name
        settings: union({ settings: {} }, store).settings
        sku: union({ sku: { name: 'Premium' } }, store).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, store).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, store).resourceGroupName)
}]
module applicationGatewaysCopy 'br/tlk:microsoft.network/application-gateways:1.0.0' = [for (gateway, index) in applicationGateways: if (contains(includedTypes, 'microsoft.network/application-gateways') && !contains(excludedTypes, 'microsoft.network/application-gateways')) {
    dependsOn: [
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-ag-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, gateway).availabilityZones
        backendAddressPools: gateway.backendAddressPools
        backendHttpSettings: gateway.backendHttpSettings
        frontEnd: gateway.frontEnd
        httpListeners: gateway.httpListeners
        identity: union({ identity: {} }, gateway).identity
        location: union({ location: location }, gateway).location
        name: union({ name: '${projectName}-ag-${padLeft(index, 5, '0')}' }, gateway).name
        routingRules: gateway.routingRules
        sku: union({ sku: {
            capacity: 1
            name: 'Standard_v2'
            tier: 'Standard_v2'
        } }, gateway).sku
        subnet: gateway.subnet
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module applicationInsightsCopy 'br/tlk:microsoft.insights/components:1.0.0' = [for (component, index) in applicationInsights: if (contains(includedTypes, 'microsoft.insights/components') && !contains(excludedTypes, 'microsoft.insights/components')) {
    dependsOn: [
        logAnalyticsWorkspacesCopy
    ]
    name: '${deployment().name}-ai-${string(index)}'
    params: {
        location: union({ location: location }, component).location
        logAnalyticsWorkspace: component.logAnalyticsWorkspace
        name: union({ name: '${projectName}-ai-${padLeft(index, 5, '0')}' }, component).name
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, component).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, component).resourceGroupName)
}]
module applicationSecurityGroupsCopy 'br/tlk:microsoft.network/application-security-groups:1.0.0' = [for (group, index) in applicationSecurityGroups: if (contains(includedTypes, 'microsoft.network/application-security-groups') && !contains(excludedTypes, 'microsoft.network/application-security-groups')) {
    name: '${deployment().name}-asg-${string(index)}'
    params: {
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-asg-${padLeft(index, 5, '0')}' }, group).name
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module applicationServicePlansCopy 'br/tlk:microsoft.web/server-farms:1.0.0' = [for (plan, index) in applicationServicePlans: if (contains(includedTypes, 'microsoft.web/server-farms') && !contains(excludedTypes, 'microsoft.web/server-farms')) {
    name: '${deployment().name}-asp-${string(index)}'
    params: {
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, plan).isZoneRedundancyEnabled
        location: union({ location: location }, plan).location
        name: union({ name: '${projectName}-asp-${padLeft(index, 5, '0')}' }, plan).name
        sku: plan.sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, plan).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, plan).resourceGroupName)
}]
module availabilitySetsCopy 'br/tlk:microsoft.compute/availability-sets:1.0.0' = [for (set, index) in availabilitySets: if (contains(includedTypes, 'microsoft.compute/availability-sets') && !contains(excludedTypes, 'microsoft.compute/availability-sets')) {
    dependsOn: [
        proximityPlacementGroupsCopy
    ]
    name: '${deployment().name}-as-${string(index)}'
    params: {
        location: union({ location: location }, set).location
        name: union({ name: '${projectName}-as-${padLeft(index, 5, '0')}' }, set).name
        numberOfFaultDomains: set.numberOfFaultDomains
        numberOfUpdateDomains: set.numberOfUpdateDomains
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, set).proximityPlacementGroup
        sku: set.sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, set).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, set).resourceGroupName)
}]
module cdnProfilesCopy 'br/tlk:microsoft.cdn/profiles:1.0.0' = [for (profile, index) in cdnProfiles: if (contains(includedTypes, 'microsoft.cdn/profiles') && !contains(excludedTypes, 'microsoft.cdn/profiles')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
    ]
    name: '${deployment().name}-cdn-${string(index)}'
    params: {
        name: union({ name: '${projectName}-cdn-${padLeft(index, 5, '0')}' }, profile).name
        sku: profile.sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, profile).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, profile).resourceGroupName)
}]
module containerRegistriesCopy 'br/tlk:microsoft.container-registry/registries:1.0.0' = [for (registry, index) in containerRegistries: if (contains(includedTypes, 'microsoft.container-registry/registries') && !contains(excludedTypes, 'microsoft.container-registry/registries')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-cr-${string(index)}'
    params: {
        identity: union({ identity: {} }, registry).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, registry).isPublicNetworkAccessEnabled
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, registry).isZoneRedundancyEnabled
        location: union({ location: location }, registry).location
        name: union({ name: '${projectName}cr${padLeft(index, 5, '0')}'}, registry).name
        sku: union({ sku: { name: 'Premium' } }, registry).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, registry).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, registry).resourceGroupName)
}]
module diskEncryptionSetsCopy 'br/tlk:microsoft.compute/disk-encryption-sets:1.0.0' = [for (set, index) in diskEncryptionSets: if (contains(includedTypes, 'microsoft.compute/disk-encryption-sets') && !contains(excludedTypes, 'microsoft.compute/disk-encryption-sets')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-des-${string(index)}'
    params: {
        identity: union({ identity: {} }, set).identity
        keyName: set.keyName
        keyVault: set.keyVault
        keyVersion: union({ keyVersion: '' }, set).keyVersion
        location: union({ location: location }, set).location
        name: union({ name: '${projectName}-des-${padLeft(index, 5, '0')}' }, set).name
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, set).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, set).resourceGroupName)
}]
module keyVaultsCopy 'br/tlk:microsoft.key-vault/vaults:1.0.0' = [for (vault, index) in keyVaults: if (contains(includedTypes, 'microsoft.key-vault/vaults') && !contains(excludedTypes, 'microsoft.key-vault/vaults')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-kv-${string(index)}'
    params: {
        firewallRules: union({ firewallRules: [] }, vault).firewallRules
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: true }, vault).isAllowTrustedMicrosoftServicesEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, vault).isPublicNetworkAccessEnabled
        isPurgeProtectionEnabled: union({ isPurgeProtectionEnabled: true }, vault).isPurgeProtectionEnabled
        isRbacAuthorizationEnabled: union({ isRbacAuthorizationEnabled: true }, vault).isRbacAuthorizationEnabled
        isTemplateDeploymentEnabled: union({ isTemplateDeploymentEnabled: true }, vault).isTemplateDeploymentEnabled
        keys: union({ keys: {} }, vault).keys
        location: union({ location: location }, vault).location
        name: union({ name: '${projectName}-kv-${padLeft(index, 5, '0')}' }, vault).name
        secrets: union({ secrets: {} }, vault).secrets
        sku: union({ sku: { name: 'premium' } }, vault).sku
        tenantId: union({ tenantId: tenant().tenantId }, vault).tenantId
        virtualNetworkRules: union({ virtualNetworkRules: [] }, vault).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, vault).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, vault).resourceGroupName)
}]
module logAnalyticsWorkspacesCopy 'br/tlk:microsoft.operational-insights/workspaces:1.0.0' = [for (workspace, index) in logAnalyticsWorkspaces: if (contains(includedTypes, 'microsoft.operational-insights/workspaces') && !contains(excludedTypes, 'microsoft.operational-insights/workspaces')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-law-${string(index)}'
    params: {
        dataRetentionInDays: union({ dataRetentionInDays: 30 }, workspace).dataRetentionInDays
        isDataExportEnabled: union({ isDataExportEnabled: true }, workspace).isDataExportEnabled
        isImmediatePurgeDataOn30DaysEnabled: union({ isImmediatePurgeDataOn30DaysEnabled: true }, workspace).isImmediatePurgeDataOn30DaysEnabled
        isPublicNetworkAccessForIngestionEnabled: union({ isPublicNetworkAccessForIngestionEnabled: false }, workspace).isPublicNetworkAccessForIngestionEnabled
        isPublicNetworkAccessForQueryEnabled: union({ isPublicNetworkAccessForQueryEnabled: false }, workspace).isPublicNetworkAccessForQueryEnabled
        location: union({ location: location }, workspace).location
        name: union({ name: '${projectName}-law-${padLeft(index, 5, '0')}' }, workspace).name
        sku: union({ sku: { name: 'PerGB2018' } }, workspace).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, workspace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, workspace).resourceGroupName)
}]
module machineLearningWorkspacesCopy 'br/tlk:microsoft.machine-learning-services/workspaces:1.0.0' = [for (workspace, index) in machineLearningWorkspaces: if (contains(includedTypes, 'microsoft.machine-learning-services/workspaces') && !contains(excludedTypes, 'microsoft.machine-learning-services/workspaces')) {
    dependsOn: [
        applicationInsightsCopy
        containerRegistriesCopy
        keyVaultsCopy
        logAnalyticsWorkspacesCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-mlw-${string(index)}'
    params: {
        applicationInsights: workspace.applicationInsights
        containerRegistry: workspace.containerRegistry
        identity: workspace.identity
        isHighBusinessImpactFeatureEnabled: union({ isHighBusinessImpactFeatureEnabled: false }, workspace).isHighBusinessImpactFeatureEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, workspace).isPublicNetworkAccessEnabled
        keyVault: workspace.keyVault
        location: union({ location: location }, workspace).location
        name: union({ name: '${projectName}-mlw-${padLeft(index, 5, '0')}' }, workspace).name
        storageAccount: workspace.storageAccount
        sku: union({ sku: { name: 'Basic' } }, workspace).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, workspace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, workspace).resourceGroupName)
}]
module natGatewaysCopy 'br/tlk:microsoft.network/nat-gateways:1.0.0' = [for (gateway, index) in natGateways: if (contains(includedTypes, 'microsoft.network/nat-gateways') && !contains(excludedTypes, 'microsoft.network/nat-gateways')) {
    dependsOn: [
        publicIpAddressesCopy
    ]
    name: '${deployment().name}-nat-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, gateway).availabilityZones
        location: union({ location: location }, gateway).location
        name: union({ name: '${projectName}-nat-${padLeft(index, 5, '0')}' }, gateway).name
        publicIpAddresses: union({ publicIpAddresses: [] }, gateway).publicIpAddresses
        publicIpPrefixes: union({ publicIpPrefixes: [] }, gateway).publicIpPrefixes
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module networkInterfacesCopy 'br/tlk:microsoft.network/network-interfaces:1.0.0' = [for (interface, index) in networkInterfaces: if (contains(includedTypes, 'microsoft.network/network-interfaces') && !contains(excludedTypes, 'microsoft.network/network-interfaces')) {
    dependsOn: [
        networkSecurityGroupsCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-nic-${string(index)}'
    params: {
        dnsServers: union({ dnsServers: [] }, interface).dnsServers
        ipConfigurations: interface.ipConfigurations
        isAcceleratedNetworkingEnabled: union({ isAcceleratedNetworkingEnabled: true }, interface).isAcceleratedNetworkingEnabled
        isIpForwardingEnabled: union({ isIpForwardingEnabled: false }, interface).isIpForwardingEnabled
        location: union({ location: location }, interface).location
        name: union({ name: '${projectName}-nic-${padLeft(index, 5, '0')}' }, interface).name
        networkSecurityGroup: union({ networkSecurityGroup: {} }, interface).networkSecurityGroup
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, interface).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, interface).resourceGroupName)
}]
module networkSecurityGroupsCopy 'br/tlk:microsoft.network/network-security-groups:1.0.0' = [for (group, index) in networkSecurityGroups: if (contains(includedTypes, 'microsoft.network/network-security-groups') && !contains(excludedTypes, 'microsoft.network/network-security-groups')) {
    dependsOn: [ applicationSecurityGroupsCopy ]
    name: '${deployment().name}-nsg-${string(index)}'
    params: {
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-nsg-${padLeft(index, 5, '0')}' }, group).name
        securityRules: group.securityRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module privateDnsZonesCopy 'br/tlk:microsoft.network/private-dns-zones:1.0.0' = [for (zone, index) in privateDnsZones: if (contains(includedTypes, 'microsoft.network/private-dns-zones') && !contains(excludedTypes, 'microsoft.network/private-dns-zones')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-dnsi-${string(index)}'
    params: {
        aRecords: union({ aRecords: [] }, zone).aRecords
        name: zone.name
        virtualNetworkLinks: union({ virtualNetworkLinks: [] }, zone).virtualNetworkLinks
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, zone).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, zone).resourceGroupName)
}]
module privateEndpointsCopy 'br/tlk:microsoft.network/private-endpoints:1.0.0' = [for (endpoint, index) in privateEndpoints: if (contains(includedTypes, 'microsoft.network/private-endpoints') && !contains(excludedTypes, 'microsoft.network/private-endpoints')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        storageAccountsCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-pe-${string(index)}'
    params: {
        applicationSecurityGroups: union({ applicationSecurityGroups: [] }, endpoint).applicationSecurityGroups
        location: location
        name: endpoint.name
        resource: endpoint.resource
        subnet: endpoint.subnet
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, endpoint).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, endpoint).resourceGroupName)
}]
module proximityPlacementGroupsCopy 'br/tlk:microsoft.compute/proximity-placement-groups:1.0.0' = [for (group, index) in proximityPlacementGroups: if (contains(includedTypes, 'microsoft.compute/proximity-placement-groups') && !contains(excludedTypes, 'microsoft.compute/proximity-placement-groups')) {
    name: '${deployment().name}-ppg-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, group).availabilityZones
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-ppg-${padLeft(index, 5, '0')}' }, group).name
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module publicDnsZonesCopy 'br/tlk:microsoft.network/dns-zones:1.0.0' = [for (zone, index) in publicDnsZones: if (contains(includedTypes, 'microsoft.network/dns-zones') && !contains(excludedTypes, 'microsoft.network/dns-zones')) {
    name: '${deployment().name}-dnse-${string(index)}'
    params: {
        cnameRecords: union({ cnameRecords: [] }, zone).cnameRecords
        name: zone.name
        txtRecords: union({ txtRecords: [] }, zone).txtRecords
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, zone).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, zone).resourceGroupName)
}]
module publicIpAddressesCopy 'br/tlk:microsoft.network/public-ip-addresses:1.0.0' = [for (address, index) in publicIpAddresses: if (contains(includedTypes, 'microsoft.network/public-ip-addresses') && !contains(excludedTypes, 'microsoft.network/public-ip-addresses')) {
    name: '${deployment().name}-pip-${string(index)}'
    params: {
        allocationMethod: address.allocationMethod
        availabilityZones: union({ availabilityZones: [] }, address).availabilityZones
        ipPrefix: union({ ipPrefix: {} }, address).ipPrefix
        location: union({ location: location }, address).location
        name: union({ name: '${projectName}-pip-${padLeft(index, 5, '0')}' }, address).name
        sku: address.sku
        version: union({ version: 'IPv4' }, address).version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, address).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, address).resourceGroupName)
}]
module publicIpPrefixesCopy 'br/tlk:microsoft.network/public-ip-prefixes:1.0.0' = [for (prefix, index) in publicIpPrefixes: if (contains(includedTypes, 'microsoft.network/public-ip-prefixes') && !contains(excludedTypes, 'microsoft.network/public-ip-prefixes')) {
    name: '${deployment().name}-pipp-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, prefix).availabilityZones
        location: union({ location: location }, prefix).location
        name: union({ name: '${projectName}-pipp-${padLeft(index, 5, '0')}' }, prefix).name
        size: prefix.size
        sku: prefix.sku
        version: union({ version: 'IPv4' }, prefix).version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, prefix).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, prefix).resourceGroupName)
}]
module serviceBusNamespacesCopy 'br/tlk:microsoft.service-bus/namespaces:1.0.0' = [for (namespace, index) in serviceBusNamespaces: if (contains(includedTypes, 'microsoft.service-bus/namespaces') && !contains(excludedTypes, 'microsoft.service-bus/namespaces')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sb-${string(index)}'
    params: {
        identity: union({ identity: {} }, namespace).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, namespace).isPublicNetworkAccessEnabled
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, namespace).isZoneRedundancyEnabled
        location: union({ location: location }, namespace).location
        name: union({ name: '${projectName}-sb-${padLeft(index, 5, '0')}' }, namespace).name
        sku: union({ sku: { name: 'Premium' } }, namespace).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, namespace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, namespace).resourceGroupName)
}]
module signalrServicesCopy 'br/tlk:microsoft.signalr-service/signalr:1.0.0' = [for (service, index) in signalrServices: if (contains(includedTypes, 'microsoft.signalr-service/signalr') && !contains(excludedTypes, 'microsoft.signalr-service/signalr')) {
    dependsOn: [
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sglr-${string(index)}'
    params: {
        cors: union({ cors: {} }, service).cors
        identity: union({ identity: {} }, service).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, service).isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, service).isSharedKeyAccessEnabled
        location: union({ location: location }, service).location
        name: union({ name: '${projectName}-sglr-${padLeft(index, 5, '0')}' }, service).name
        serverless: union({ serverless: {} }, service).serverless
        sku: union({ sku: { name: 'Standard_S1' } }, service).sku
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, service).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, service).resourceGroupName)
}]
module sqlServersCopy 'br/tlk:microsoft.sql/servers:1.0.0' = [for (server, index) in sqlServers: if (contains(includedTypes, 'microsoft.sql/servers') && !contains(excludedTypes, 'microsoft.sql/servers')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sql-${string(index)}'
    params: {
        administrator: union({ name: uniqueString('${projectName}-sql-${padLeft(index, 5, '0')}') }, server.administrator)
        firewallRules: union({ firewallRules: [] }, server).firewallRules
        identity: union({ identity: {} }, server).identity
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, server).isAllowTrustedMicrosoftServicesEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, server).isPublicNetworkAccessEnabled
        isSqlAuthenticationEnabled: union({ isSqlAuthenticationEnabled: false }, server).isSqlAuthenticationEnabled
        location: union({ location: location }, server).location
        name: union({ name: '${projectName}-sql-${padLeft(index, 5, '0')}' }, server).name
        virtualNetworkRules: union({ virtualNetworkRules: [] }, server).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, server).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, server).resourceGroupName)
}]
module storageAccountsCopy 'br/tlk:microsoft.storage/storage-accounts:1.0.0' = [for (account, index) in storageAccounts: if (contains(includedTypes, 'microsoft.storage/storage-accounts') && !contains(excludedTypes, 'microsoft.storage/storage-accounts')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-data-${string(index)}'
    params: {
        accessTier: union({ accessTier: 'Hot' }, account).accessTier
        firewallRules: union({ firewallRules: [] }, account).firewallRules
        identity: union({ identity: {} }, account).identity
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, account).isAllowTrustedMicrosoftServicesEnabled
        isHttpsOnlyModeEnabled: union({ isHttpsOnlyModeEnabled: true }, account).isHttpsOnlyModeEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, account).isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, account).isSharedKeyAccessEnabled
        kind: account.kind
        location: union({ location: location }, account).location
        name: union({ name: '${projectName}data${padLeft(index, 5, '0')}' }, account).name
        services: account.services
        sku: account.sku
        virtualNetworkRules: union({ virtualNetworkRules: [] }, account).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, account).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, account).resourceGroupName)
}]
module userAssignedIdentitiesCopy 'br/tlk:microsoft.managed-identity/user-assigned-identities:1.0.0' = [for (identity, index) in userAssignedIdentities: if (contains(includedTypes, 'microsoft.managed-identity/user-assigned-identities') && !contains(excludedTypes, 'microsoft.managed-identity/user-assigned-identities')) {
    name: '${deployment().name}-mi-${string(index)}'
    params: {
        location: union({ location: location }, identity).location
        name: union({ name: '${projectName}-mi-${padLeft(index, 5, '0')}' }, identity).name
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, identity).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, identity).resourceGroupName)
}]
module virtualMachinesCopy 'br/tlk:microsoft.compute/virtual-machines:1.0.0' = [for (machine, index) in virtualMachines: if (contains(includedTypes, 'microsoft.compute/virtual-machines') && !contains(excludedTypes, 'microsoft.compute/virtual-machines')) {
    dependsOn: [
        applicationSecurityGroupsCopy
        availabilitySetsCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        proximityPlacementGroupsCopy
        privateDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-vm-${string(index)}'
    params: {
        administrator: machine.administrator
        availabilitySet: union({ availabilitySet: {} }, machine).availabilitySet
        availabilityZones: union({ availabilityZones: [] }, machine).availabilityZones
        identity: union({ identity: {} }, machine).identity
        imageReference: machine.imageReference
        linuxConfiguration: union({ linuxConfiguration: {} }, machine).linuxConfiguration
        location: union({ location: location }, machine).location
        name: union({ name: '${projectName}vm${padLeft(index, 5, '0')}' }, machine).name
        networkInterfaces: machine.networkInterfaces
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, machine).proximityPlacementGroup
        sku: machine.sku
        subnet: union({ subnet: {} }, machine).subnet
        windowsConfiguration: union({ windowsConfiguration: {} }, machine).windowsConfiguration
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, machine).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, machine).resourceGroupName)
}]
module virtualNetworkGatewaysCopy 'br/tlk:microsoft.network/virtual-network-gateways:1.0.0' = [for (gateway, index) in virtualNetworkGateways: if (contains(includedTypes, 'microsoft.network/virtual-network-gateways') && !contains(excludedTypes, 'microsoft.network/virtual-network-gateways')) {
    dependsOn: [
        publicIpAddressesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-vng-${string(index)}'
    params: {
        clientConfiguration: gateway.clientConfiguration
        generation: gateway.generation
        ipConfigurations: gateway.ipConfigurations
        isActiveActiveModeEnabled: gateway.isActiveActiveModeEnabled
        location: union({ location: location }, gateway).location
        mode: gateway.mode
        name: union({ name: '${projectName}-vng-${padLeft(index, 5, '0')}' }, gateway).name
        sku: gateway.sku
        type: gateway.type
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module virtualNetworksCopy 'br/tlk:microsoft.network/virtual-networks:1.0.0' = [for (network, index) in virtualNetworks: if (contains(includedTypes, 'microsoft.network/virtual-networks') && !contains(excludedTypes, 'microsoft.network/virtual-networks')) {
    dependsOn: [
        natGatewaysCopy
        networkSecurityGroupsCopy
    ]
    name: '${deployment().name}-vnet-${string(index)}'
    params: {
        addressPrefixes: network.addressPrefixes
        ddosProtectionPlan: {}
        dnsServers: network.dnsServers
        location: union({ location: location }, network).location
        name: union({ name: '${projectName}-vnet-${padLeft(index, 5, '0')}' }, network).name
        subnets: network.subnets
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, network).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, network).resourceGroupName)
}]
module webApplicationsCopy 'br/tlk:microsoft.web/sites:1.0.0' = [for (application, index) in webApplications: if (contains(includedTypes, 'microsoft.web/sites') && !contains(excludedTypes, 'microsoft.web/sites')) {
    dependsOn: [
        applicationConfigurationStoresCopy
        applicationInsightsCopy
        applicationServicePlansCopy
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
        serviceBusNamespacesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-web-${string(index)}'
    params: {
        applicationInsights: union({ applicationInsights: {} }, application).applicationInsights
        applicationSettings: union({ applicationSettings: {} }, application).applicationSettings
        cors: union({ cors: {} }, application).cors
        functionExtension: union({ functionExtension: {} }, application).functionExtension
        identity: union({ identity: {} }, application).identity
        is32BitModeEnabled: union({ is32BitModeEnabled: false }, application).is32BitModeEnabled
        location: union({ location: location }, application).location
        name: union({ name: '${projectName}-web-${padLeft(index, 5, '0')}' }, application).name
        servicePlan: application.servicePlan
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, application).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, application).resourceGroupName)
}]

resource deploymentsCopy 'Microsoft.Resources/deployments@2021-04-01' = [for (deployment, index) in deployments: if (contains(includedTypes, 'microsoft.resources/deployments') && !contains(excludedTypes, 'microsoft.resources/deployments')) {
    dependsOn: [
        applicationConfigurationStoresCopy
        applicationGatewaysCopy
        applicationInsightsCopy
        applicationSecurityGroupsCopy
        applicationServicePlansCopy
        availabilitySetsCopy
        containerRegistriesCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        logAnalyticsWorkspacesCopy
        machineLearningWorkspacesCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        privateDnsZonesCopy
        privateEndpointsCopy
        proximityPlacementGroupsCopy
        publicDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        roleAssignmentsCopy
        serviceBusNamespacesCopy
        signalrServicesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualMachinesCopy
        virtualNetworkGatewaysCopy
        virtualNetworksCopy
        webApplicationsCopy
    ]
    name: '${deployment().name}-rm-${string(index)}'
    properties: {
        expressionEvaluationOptions: {
            scope: 'NotSpecified'
        }
        mode: union({ mode: 'Incremental' }, deployment).mode
        parameters: union({ parameters: {} }, deployment).parameters
        parametersLink: union({ parametersLink: null }, deployment).parametersLink
        template: union({ template: null }, deployment).template
        templateLink: union({ templateLink: null }, deployment).templateLink
    }
    resourceGroup: union({ resourceGroupName: resourceGroup().name }, deployment).resourceGroupName
    subscriptionId: union({ subscriptionId: subscription().subscriptionId }, deployment).subscriptionId
}]
resource roleAssignmentsCopy 'Microsoft.Resources/deployments@2021-04-01' = [for (assignment, index) in roleAssignments: if (contains(includedTypes, 'microsoft.authorization/role-assignments') && !contains(excludedTypes, 'microsoft.authorization/role-assignments')) {
    dependsOn: [
        applicationConfigurationStoresCopy
        applicationGatewaysCopy
        applicationInsightsCopy
        applicationSecurityGroupsCopy
        applicationServicePlansCopy
        availabilitySetsCopy
        containerRegistriesCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        logAnalyticsWorkspacesCopy
        machineLearningWorkspacesCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        privateDnsZonesCopy
        privateEndpointsCopy
        proximityPlacementGroupsCopy
        publicDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        serviceBusNamespacesCopy
        signalrServicesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualMachinesCopy
        virtualNetworkGatewaysCopy
        virtualNetworksCopy
        webApplicationsCopy
    ]
    name: '${deployment().name}-rbac-${string(index)}'
    properties: {
        expressionEvaluationOptions: {
            scope: 'NotSpecified'
        }
        mode: 'Incremental'
        parameters: {
            assignee: {
                value: assignment.assignee
            }
            assignor: {
                value: assignment.assignor
            }
            roleDefinitionName: {
                value: assignment.roleDefinitionName
            }
        }
        templateLink: {
            contentVersion: '1.0.0.0'
            id: resourceId('fd49ea67-135b-449f-a62c-3e4b8d26d3d6', 'thelankrew', 'Microsoft.Resources/templateSpecs/versions', 'microsoft.authorization_role-assignments', '1.0.0')
        }
    }
    resourceGroup: resourceGroup().name
    subscriptionId: subscription().subscriptionId
}]
