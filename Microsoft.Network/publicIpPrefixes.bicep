@description('An array of availability zones that the Azure Public IP Prefix will be deployed within.')
param availabilityZones array
@description('Specifies the location in which the Azure Public IP Prefix resource(s) will be deployed.')
param location string
@description('Specifies the name of the Azure Public IP Prefix.')
param name string
@description('Specifies the size of the Azure Public IP Prefix.')
param size int
@description('Specifies the SKU name of the Azure Public IP Prefix.')
param skuName string
@description('Specifies the SKU tier of the Azure Public IP Prefix.')
param skuTier string
@description('Specifies the version of the Azure Public IP Prefix.')
param version string

var zones = [for zone in availabilityZones: string(zone)]

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2022-01-01' = {
    location: location
    name: name
    properties: {
        prefixLength: size
        publicIPAddressVersion: version
    }
    sku: {
        name: skuName
        tier: skuTier
    }
    zones: zones
}
