param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  location: location
  name: name
  properties: {
    virtualNetwork: {
      id: virtualNetworkRef.id
    }
  }
  tags: tags
}
resource inboundEndpoints 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = [for (endpoint, index) in properties.inboundEndpoints: {
  location: location
  name: (endpoint.?name ?? index)
  parent: dnsResolver
  properties: {
    ipConfigurations: [
      {
        privateIpAddress: (endpoint.privateIpAddress.?value ?? null)
        privateIpAllocationMethod: (contains(endpoint.privateIpAddress, 'value') ? 'Static' : 'Dynamic')
        subnet: {
          id: inboundSubnetsRef[index].id
        }
      }
    ]
  }
  tags: (endpoint.?tags ?? tags)
}]
resource inboundSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in properties.inboundEndpoints: {
  name: '${endpoint.privateIpAddress.subnet.name}'
  parent: virtualNetworkRef
}]
resource outboundEndpoints 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = [for (endpoint, index) in properties.outboundEndpoints: {
  location: location
  name: (endpoint.?name ?? index)
  parent: dnsResolver
  properties: {
    subnet: {
      id: outboundSubnetsRef[index].id
    }
  }
  tags: (endpoint.?tags ?? tags)
}]
resource outboundSubnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for endpoint in properties.outboundEndpoints: {
  name: '${endpoint.subnet.name}'
  parent: virtualNetworkRef
}]
resource virtualNetworkRef 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: properties.virtualNetwork.name
  scope: resourceGroup((properties.virtualNetwork.?subscriptionId ?? subscriptionId), (properties.virtualNetwork.?resourceGroupName ?? resourceGroupName))
}
