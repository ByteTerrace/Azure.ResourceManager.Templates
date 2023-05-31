param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isCustomPrefixNotEmpty = !empty(properties.?customPrefix ?? {})
var isNatGatewayNotEmpty = !empty(properties.?natGateway ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource customPrefix 'Microsoft.Network/customIpPrefixes@2022-11-01' existing = if (isCustomPrefixNotEmpty) {
  name: properties.customPrefix.name
  scope: resourceGroup((properties.customPrefix.?subscriptionId ?? subscriptionId), (properties.customPrefix.?resourceGroupName ?? resourceGroupName))
}
resource natGateway 'Microsoft.Network/natGateways@2022-11-01' existing = if (isNatGatewayNotEmpty) {
  name: properties.natGateway.name
  scope: resourceGroup((properties.natGateway.?subscriptionId ?? subscriptionId), (properties.natGateway.?resourceGroupName ?? resourceGroupName))
}
resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2022-11-01' = {
  location: location
  name: name
  properties: {
    customIPPrefix: (isCustomPrefixNotEmpty ? { id: customPrefix.id } : null)
    natGateway: (isNatGatewayNotEmpty ? { id: natGateway.id } : null)
    prefixLength: properties.length
    publicIPAddressVersion: (properties.?version ?? 'IPv4')
  }
  sku: properties.sku
  tags: tags
}
