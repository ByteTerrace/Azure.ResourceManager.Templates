param location string = 'West US 3'
param projectName string = 'tlk'
param overrides object = {
    excludedTypes: []
    includedTypes: []
}

// variables
var excludedTypes = [for type in overrides.excludedTypes: toLower(type)]
var includedTypes = [for type in empty(overrides.includedTypes) ? [
    'microsoft.compute/availability-sets'
    'microsoft.compute/proximity-placement-groups'
    'microsoft.compute/virtual-machines'
    'microsoft.container-registry/registries'
    'microsoft.key-vault/vaults'
    'microsoft.managed-identity/user-assigned-identities'
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
    'microsoft.storage/storage-accounts'
] : overrides.includedTypes: toLower(type)]

// resource definitions
var applicationSecurityGroups = [
    {}
]
var availabilitySets = [
    {
        proximityPlacementGroup: {
            name: 'tlk-ppg-00000'
        }
        numberOfFaultDomains: 3
        numberOfUpdateDomains: 5
        skuName: 'Aligned'
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
        skuName: 'Basic'
    }
]
var keyVaults = [
    {}
]
var managedIdentities = [
    {}
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
                        allocationMethod: 'Static'
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
        skuName: 'Basic'
        skuTier: 'Regional'
    }
    {
        allocationMethod: 'Static'
        skuName: 'Standard'
        skuTier: 'Regional'
    }
]
var publicIpPrefixes = []
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
        skuName: 'Standard_LRS'
    }
]
var virtualMachines = [
    {
        administrator: {
            password: 'Mandy0143Fd!'
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
        skuName: 'Standard_B1ms'
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
        skuName: 'Basic'
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

// module imports
module applicationSecurityGroupsCopy 'br/tlk:microsoft.network/application-security-groups:1.0.0' = [for (group, index) in applicationSecurityGroups: if (contains(includedTypes, 'microsoft.network/application-security-groups') && !contains(excludedTypes, 'microsoft.network/application-security-groups')) {
    name: '${deployment().name}-asg-${string(index)}'
    params: {
        location: location
        name: '${projectName}-asg-${padLeft(index, 5, '0')}'
    }
}]
module availabilitySetsCopy 'br/tlk:microsoft.compute/availability-sets:1.0.0' = [for (set, index) in availabilitySets: if (contains(includedTypes, 'microsoft.compute/availability-sets') && !contains(excludedTypes, 'microsoft.compute/availability-sets')) {
    dependsOn: [
        proximityPlacementGroupsCopy
    ]
    name: '${deployment().name}-as-${string(index)}'
    params: {
        location: location
        name: '${projectName}-as-${padLeft(index, 5, '0')}'
        numberOfFaultDomains: set.numberOfFaultDomains
        numberOfUpdateDomains: set.numberOfUpdateDomains
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, set).proximityPlacementGroup
        skuName: set.skuName
    }
}]
module containerRegistriesCopy 'br/tlk:microsoft.container-registry/registries:1.0.0' = [for (registry, index) in containerRegistries: if (contains(includedTypes, 'microsoft.container-registry/registries') && !contains(excludedTypes, 'microsoft.container-registry/registries')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-cr-${string(index)}'
    params: {
        identity: registry.identity
        isPublicNetworkAccessEnabled: registry.isPublicNetworkAccessEnabled
        location: location
        name: '${projectName}cr${padLeft(index, 5, '0')}'
        skuName: registry.skuName
    }
}]
module keyVaultsCopy 'br/tlk:microsoft.key-vault/vaults:1.0.0' = [for (vault, index) in keyVaults: if (contains(includedTypes, 'microsoft.key-vault/vaults') && !contains(excludedTypes, 'microsoft.key-vault/vaults')) {
    dependsOn: [
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-kv-${string(index)}'
    params: {
        location: location
        name: '${projectName}-kv-${padLeft(index, 5, '0')}'
    }
}]
module natGatewaysCopy 'br/tlk:microsoft.network/nat-gateways:1.0.0' = [for (gateway, index) in natGateways: if (contains(includedTypes, 'microsoft.network/nat-gateways') && !contains(excludedTypes, 'microsoft.network/nat-gateways')) {
    dependsOn: [
        publicIpAddressesCopy
    ]
    name: '${deployment().name}-nat-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, gateway).availabilityZones
        location: location
        name: '${projectName}-nat-${padLeft(index, 5, '0')}'
        publicIpAddresses: union({ publicIpAddresses: [] }, gateway).publicIpAddresses
        publicIpPrefixes: union({ publicIpPrefixes: [] }, gateway).publicIpPrefixes
    }
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
        location: location
        name: '${projectName}-nic-${padLeft(index, 5, '0')}'
        networkSecurityGroup: union({ networkSecurityGroup: {} }, interface).networkSecurityGroup
    }
}]
module networkSecurityGroupsCopy 'br/tlk:microsoft.network/network-security-groups:1.0.0' = [for (group, index) in networkSecurityGroups: if (contains(includedTypes, 'microsoft.network/network-security-groups') && !contains(excludedTypes, 'microsoft.network/network-security-groups')) {
    dependsOn: [ applicationSecurityGroupsCopy ]
    name: '${deployment().name}-nsg-${string(index)}'
    params: {
        location: location
        name: '${projectName}-nsg-${padLeft(index, 5, '0')}'
        securityRules: group.securityRules
    }
}]
module privateDnsZonesCopy 'br/tlk:microsoft.network/private-dns-zones:1.0.0' = [for (zone, index) in privateDnsZones: if (contains(includedTypes, 'microsoft.network/private-dns-zones') && !contains(excludedTypes, 'microsoft.network/private-dns-zones')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-privatedns-${string(index)}'
    params: {
        aRecords: union({ aRecords: [] }, zone).aRecords
        name: zone.name
        virtualNetworkLinks: union({ virtualNetworkLinks: [] }, zone).virtualNetworkLinks
    }
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
}]
module proximityPlacementGroupsCopy 'br/tlk:microsoft.compute/proximity-placement-groups:1.0.0' = [for (group, index) in proximityPlacementGroups: if (contains(includedTypes, 'microsoft.compute/proximity-placement-groups') && !contains(excludedTypes, 'microsoft.compute/proximity-placement-groups')) {
    name: '${deployment().name}-ppg-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, group).availabilityZones
        location: location
        name: '${projectName}-ppg-${padLeft(index, 5, '0')}'
    }
}]
module publicDnsZonesCopy 'br/tlk:microsoft.network/dns-zones:1.0.0' = [for (zone, index) in publicDnsZones: if (contains(includedTypes, 'microsoft.network/dns-zones') && !contains(excludedTypes, 'microsoft.network/dns-zones')) {
    name: '${deployment().name}-publicdns-${string(index)}'
    params: {
        cnameRecords: union({ cnameRecords: [] }, zone).cnameRecords
        name: zone.name
        txtRecords: union({ txtRecords: [] }, zone).txtRecords
    }
}]
module publicIpAddressesCopy 'br/tlk:microsoft.network/public-ip-addresses:1.0.0' = [for (address, index) in publicIpAddresses: if (contains(includedTypes, 'microsoft.network/public-ip-addresses') && !contains(excludedTypes, 'microsoft.network/public-ip-addresses')) {
    name: '${deployment().name}-pip-${string(index)}'
    params: {
        allocationMethod: address.allocationMethod
        availabilityZones: union({ availabilityZones: [] }, address).availabilityZones
        ipPrefix: union({ ipPrefix: {} }, address).ipPrefix
        location: location
        name: '${projectName}-pip-${padLeft(index, 5, '0')}'
        skuName: address.skuName
        skuTier: address.skuTier
        version: union({ version: 'IPv4' }, address).version
    }
}]
module publicIpPrefixesCopy 'br/tlk:microsoft.network/public-ip-prefixes:1.0.0' = [for (prefix, index) in publicIpPrefixes: if (contains(includedTypes, 'microsoft.network/public-ip-prefixes') && !contains(excludedTypes, 'microsoft.network/public-ip-prefixes')) {
    name: '${deployment().name}-pipp-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, prefix).availabilityZones
        location: location
        name: '${projectName}-pipp-${padLeft(index, 5, '0')}'
        size: prefix.size
        skuName: prefix.skuName
        skuTier: prefix.skuTier
        version: union({ version: 'IPv4' }, prefix).version
    }
}]
module storageAccountsCopy 'br/tlk:microsoft.storage/storage-accounts:1.0.0' = [for (account, index) in storageAccounts: if (contains(includedTypes, 'microsoft.storage/storage-accounts') && !contains(excludedTypes, 'microsoft.storage/storage-accounts')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-data-${string(index)}'
    params: {
        accessTier: account.accessTier
        identity: account.identity
        isHttpsOnlyModeEnabled: account.isHttpsOnlyModeEnabled
        isPublicNetworkAccessEnabled: account.isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: account.isSharedKeyAccessEnabled
        kind: account.kind
        location: location
        name: '${projectName}data${padLeft(index, 5, '0')}'
        services: account.services
        skuName: account.skuName
    }
}]
module userAssignedIdentitiesCopy 'br/tlk:microsoft.managed-identity/user-assigned-identities:1.0.0' = [for (identity, index) in managedIdentities: if (contains(includedTypes, 'microsoft.managed-identity/user-assigned-identities') && !contains(excludedTypes, 'microsoft.managed-identity/user-assigned-identities')) {
    name: '${deployment().name}-mi-${string(index)}'
    params: {
        location: location
        name: '${projectName}-mi-${padLeft(index, 5, '0')}'
    }
}]
module virtualMachinesCopy 'br/tlk:microsoft.compute/virtual-machines:1.0.0' = [for (machine, index) in virtualMachines: if (contains(includedTypes, 'microsoft.compute/virtual-machines') && !contains(excludedTypes, 'microsoft.compute/virtual-machines')) {
    dependsOn: [
        availabilitySetsCopy
        networkInterfacesCopy
        proximityPlacementGroupsCopy
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
        location: location
        name: '${projectName}vm${padLeft(index, 5, '0')}'
        networkInterfaces: machine.networkInterfaces
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, machine).proximityPlacementGroup
        skuName: machine.skuName
        subnet: union({ subnet: {} }, machine).subnet
        windowsConfiguration: union({ windowsConfiguration: {} }, machine).windowsConfiguration
    }
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
        location: location
        mode: gateway.mode
        name: '${projectName}-vng-${padLeft(index, 5, '0')}'
        skuName: gateway.skuName
        type: gateway.type
    }
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
        location: location
        name: '${projectName}-vnet-${padLeft(index, 5, '0')}'
        subnets: network.subnets
    }
}]
