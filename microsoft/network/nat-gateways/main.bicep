param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var publicIpAddresses = items(properties.?publicIpAddresses ?? {})
var publicIpPrefixes = items(properties.?publicIpPrefixes ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource natGateway 'Microsoft.Network/natGateways@2022-11-01' = {
  location: location
  name: name
  properties: {
    idleTimeoutInMinutes: (properties.?idleTimeoutInMinutes ?? null)
    publicIpAddresses: [for (address, index) in publicIpAddresses: { id: publicIpAddressesRef[index].id }]
    publicIpPrefixes: [for (prefix, index) in publicIpPrefixes: { id: publicIpPrefixesRef[index].id }]
  }
  sku: properties.sku
  tags: tags
}
resource publicIpAddressesRef 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = [for address in publicIpAddresses: {
  name: address.key
  scope: resourceGroup((address.value.?subscriptionId ?? subscriptionId), (address.value.?resourceGroupName ?? resourceGroupName))
}]
resource publicIpPrefixesRef 'Microsoft.Network/publicIPPrefixes@2022-11-01' existing = [for prefix in publicIpPrefixes: {
  name: prefix.key
  scope: resourceGroup((prefix.value.?subscriptionId ?? subscriptionId), (prefix.value.?resourceGroupName ?? resourceGroupName))
}]
