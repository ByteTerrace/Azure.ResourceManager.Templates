@description('Indicates whether the Azure Application Service Environment will be deployed onto dedicated hosts instead of provisioned on a multi-tenant hypervisor.')
param isDedicatedHostGroup bool = false
@description('Indicates whether all internal traffic within the Azure Application Service Environment will be encrypted.')
param isInternalEncryptionEnabled bool = false
@description('Indicates whether the the Azure Application Service Environment will be configured to only support the set of SSL cipher suites that are required in order to function.')
param isMinimalSslCipherSuiteConfigurationEnabled bool = true
@description('Indicates whether the zone redundancy feature is enabled on the Azure Application Service Environment.')
param isZoneRedundancyEnabled bool = true
@description('Specifies the kind of the Azure Application Service Environment.')
param kind string = 'ASEV3'
@description('Specifies the location in which the Azure Application Service Environment resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Service Environment.')
param name string
@description('An object that encapsulates the properties of the subnet that the Azure Application Service Environment will be deployed within.')
param subnet object
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Application Service Environment.')
param tags object = {}

resource hostingEnvironment 'Microsoft.Web/hostingEnvironments@2022-03-01' = {
    kind: kind
    location: location
    name: name
    properties: {
        clusterSettings: union([
            {
                name: 'DisableTls1.0'
                value: '1'
            }
        ], isInternalEncryptionEnabled ? [
            {
                name: 'InternalEncryption'
                value: 'true'
            }
        ] : [], isMinimalSslCipherSuiteConfigurationEnabled ? [
            {
                name: 'FrontEndSSLCipherSuiteOrder.0'
                value: 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
            }
        ] : [])
        dedicatedHostCount: isDedicatedHostGroup ? 2 : 0
        internalLoadBalancingMode: 'Web, Publishing'
        upgradePreference: 'None'
        virtualNetwork: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, subnet).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
        }
        zoneRedundant: isZoneRedundancyEnabled
    }
    tags: tags
}
