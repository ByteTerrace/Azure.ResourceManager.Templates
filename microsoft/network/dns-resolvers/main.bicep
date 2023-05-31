param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var endpoints = {
  inbound: sort(items(properties.?inboundEndpoints ?? {}), (x, y) => (x.key < y.key))
  outbound: sort(items(properties.?outboundEndpoints ?? {}), (x, y) => (x.key < y.key))
}
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  location: location
  name: name
  properties: {
    virtualNetwork: { id: virtualNetworkRef.id }
  }
  tags: tags
}
resource inboundEndpoints 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = [for (endpoint, index) in endpoints.inbound: {
  location: location
  name: endpoint.key
  parent: dnsResolver
  properties: {
    ipConfigurations: [
      {
        privateIpAddress: (endpoint.value.privateIpAddress.?value ?? null)
        privateIpAllocationMethod: (contains(endpoint.value.privateIpAddress, 'value') ? 'Static' : 'Dynamic')
        subnet: { id: inboundSubnetsRef[index].id }
      }
    ]
  }
  tags: (endpoint.value.?tags ?? tags)
}]
resource inboundSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in endpoints.inbound: {
  name: '${endpoint.value.privateIpAddress.subnet.name}'
  parent: virtualNetworkRef
}]
resource outboundEndpoints 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = [for (endpoint, index) in endpoints.outbound: {
  location: location
  name: endpoint.key
  parent: dnsResolver
  properties: {
    subnet: { id: outboundSubnetsRef[index].id }
  }
  tags: (endpoint.value.?tags ?? tags)
}]
resource outboundSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in endpoints.outbound: {
  name: '${endpoint.value.subnet.name}'
  parent: virtualNetworkRef
}]
resource virtualNetworkRef 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: properties.virtualNetwork.name
  scope: resourceGroup((properties.virtualNetwork.?subscriptionId ?? subscriptionId), (properties.virtualNetwork.?resourceGroupName ?? resourceGroupName))
}
