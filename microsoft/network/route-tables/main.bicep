param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

resource routeTable 'Microsoft.Network/routeTables@2022-11-01' = {
  location: location
  name: name
  properties: {
    routes: [for route in (properties.?routes ?? []): {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefixOrServiceTag
        hasBgpOverride: null
        nextHopType: route.nextHopType
        nextHopIpAddress: (route.?nextHopIpAddress ?? null)
      }
    }]
  }
  tags: tags
}
