param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isPrefixNotEmpty = !empty(properties.?prefix ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource ipAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  location: location
  name: name
  properties: {
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
    deleteOption: (properties.?deleteOption ?? 'Detach')
    idleTimeoutInMinutes: (properties.?idleTimeoutInMinutes ?? null)
    publicIPAddressVersion: (properties.?version ?? 'IPv4')
    publicIPAllocationMethod: (properties.?allocationMethod ?? 'Static')
    publicIPPrefix: (isPrefixNotEmpty ? { id: ipPrefixRef.id } : null)
  }
  sku: properties.sku
  tags: tags
}
resource ipPrefixRef 'Microsoft.Network/publicIPPrefixes@2022-11-01' existing = if (isPrefixNotEmpty) {
  name: properties.prefix.name
  scope: resourceGroup((properties.prefix.?subscriptionId ?? subscriptionId), (properties.prefix.?resourceGroupName ?? resourceGroupName))
}
