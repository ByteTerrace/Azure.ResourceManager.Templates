@description('An array of A records that will be created within the Azure Private DNS Zone.')
param aRecords array
@description('Specifies the name of the Azure DNS Zone.')
param name string
@description('An array of virtual networks that the Azure DNS Zone will be linked with.')
param virtualNetworkLinks array

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
    location: 'global'
    name: name
    properties: {}
}

resource virtualNetworkLinksCopy 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for link in virtualNetworkLinks: {
    location: 'global'
    name: union({ name: uniqueString(resourceId(union({
        subscriptionId: subscription().subscriptionId
    }, link.virtualNetwork).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, link.virtualNetwork).resourceGroupName, 'Microsoft.Network/virtualNetworks', link.virtualNetwork.name)) }, link).name
    parent: privateDnsZone
    properties: {
        registrationEnabled: union({ isAutomaticVmRegistrationEnabled: false }, link).isAutomaticVmRegistrationEnabled
        virtualNetwork: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, link.virtualNetwork).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, link.virtualNetwork).resourceGroupName, 'Microsoft.Network/virtualNetworks', link.virtualNetwork.name)
        }
    }
}]

resource aRecordsCopy 'Microsoft.Network/privateDnsZones/A@2020-06-01' = [for record in aRecords: {
    name: record.name
    parent: privateDnsZone
    properties: {
        aRecords: [for address in record.ipAddresses: {
            ipv4Address: address
        }]
        metadata: union({ metadata: {} }, record).metadata
        ttl: union({ timeToLiveInSeconds: 3600 }, record).timeToLiveInSeconds
    }
}]
