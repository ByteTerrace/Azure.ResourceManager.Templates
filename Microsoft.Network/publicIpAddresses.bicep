@description('Specifies the allocation method of the Azure Public IP Address.')
param allocationMethod string = 'Static'
@description('An array of availability zones that the Azure Public IP Address will be deployed within.')
param availabilityZones array = []
@description('An object that encapsulates the properties of the Azure Public IP prefix that this Azure Public IP Address will be derived from.')
param ipPrefix object = {}
@description('Specifies the location in which the Azure Public IP Address resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Public IP Address.')
param name string
@description('Specifies the SKU of the Azure Public IP Address.')
param sku object = {
    name: 'Standard'
    tier: 'Regional'
}
@description('Specifies the version of the Azure Public IP Address.')
param version string = 'IPv4'

var zones = [for zone in availabilityZones: string(zone)]

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
    location: location
    name: name
    properties: {
        deleteOption: 'Detach'
        idleTimeoutInMinutes: 4
        ipTags: []
        publicIPAddressVersion: version
        publicIPAllocationMethod: allocationMethod
        publicIPPrefix: empty(ipPrefix) ? null : {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, ipPrefix).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, ipPrefix).resourceGroupName, 'Microsoft.Network/publicIPPrefixes', ipPrefix.name)
        }
    }
    sku: sku
    zones: zones
}
