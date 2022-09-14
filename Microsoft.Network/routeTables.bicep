@description('Indicates whether the BGP route propagation feature is enabled on the Azure Route Table.')
param isBgpRoutePropagationEnabled bool = false
@description('Specifies the location in which the Azure Route Table resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Route Table.')
param name string
@description('An array of routes that will be created within the Azure Route Table.')
param routes array = []
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Route Table.')
param tags object = {}

resource symbolicname 'Microsoft.Network/routeTables@2022-01-01' = {
    location: location
    name: name
    properties: {
        disableBgpRoutePropagation: isBgpRoutePropagationEnabled
        routes: [for route in routes: {
            name: route.name
            properties: {
                addressPrefix: route.addressPrefix
                nextHopIpAddress: route.nextHopIpAddress
                nextHopType: route.nextHopType
            }
        }]
    }
    tags: tags
}
