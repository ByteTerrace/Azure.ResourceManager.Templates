param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

resource routeTable 'Microsoft.Network/routeTables@2022-11-01' = {
  location: location
  name: name
  properties: {
    routes: [for route in sort(items(properties.?routes ?? {}), (x, y) => (x.key < y.key)): {
      name: route.key
      properties: {
        addressPrefix: route.value.addressPrefix
        hasBgpOverride: null
        nextHopType: route.value.nextHopType
        nextHopIpAddress: (route.value.?nextHopIpAddress ?? null)
      }
    }]
  }
  tags: tags
}
