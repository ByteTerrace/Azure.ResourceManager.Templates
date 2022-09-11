@description('An array of availability zones that the Azure NAT Gateway will be deployed within.')
param availabilityZones array
@description('Specifies the location in which the Azure NAT Gateway resource(s) will be deployed.')
param location string
@description('Specifies the name of the Azure NAT Gateway.')
param name string
@description('An array of public IP addresses that the Azure NAT Gateway will be associated with.')
param publicIpAddresses array
@description('An array of public IP prefixes that the Azure NAT Gateway will be associated with.')
param publicIpPrefixes array

var zones = [for zone in availabilityZones: string(zone)]

resource natGateway 'Microsoft.Network/natGateways@2022-01-01' = {
    location: location
    name: name
    properties: {
        idleTimeoutInMinutes: 4
        publicIpAddresses: [for address in publicIpAddresses: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, address).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, address).resourceGroupName, 'Microsoft.Network/publicIPAddresses', address.name)
        }]
        publicIpPrefixes: [for prefix in publicIpPrefixes: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, prefix).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, prefix).resourceGroupName, 'Microsoft.Network/publicIPPrefixes', prefix.name)
        }]
    }
    sku: {
        name: 'Standard'
    }
    zones: zones
}
