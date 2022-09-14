@description('An array of availability zones that the Azure Public IP Prefix will be deployed within.')
param availabilityZones array = []
@description('Specifies the location in which the Azure Public IP Prefix resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Public IP Prefix.')
param name string
@description('Specifies the size of the Azure Public IP Prefix.')
param size int = 32
@description('Specifies the SKU of the Azure Public IP Prefix.')
param sku object = {
    name: 'Standard'
    tier: 'Regional'
}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Public IP Prefix.')
param tags object = {}
@description('Specifies the version of the Azure Public IP Prefix.')
param version string = 'IPv4'

var zones = [for zone in availabilityZones: string(zone)]

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2022-01-01' = {
    location: location
    name: name
    properties: {
        prefixLength: size
        publicIPAddressVersion: version
    }
    sku: sku
    tags: tags
    zones: zones
}
