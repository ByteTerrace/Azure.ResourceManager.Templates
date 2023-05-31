param location string = resourceGroup().location
param name string
param properties object
param tags object = {}

var isNetworkSecurityGroupNotEmpty = !empty(properties.?networkInterface ?? {})
var ipConfigurations = sort(items(properties.ipConfigurations), (x, y) => (x.key < y.key))
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  location: location
  name: name
  properties: {
    dnsSettings: {
      dnsServers: (properties.?dnsServers ?? [])
    }
    disableTcpStateTracking: !(properties.?isTcpStateTrackingEnabled ?? true)
    enableAcceleratedNetworking: (properties.?isAcceleratedNetworkingEnabled ?? true)
    enableIPForwarding: (properties.?isIpForwardingEnabled ?? null)
    ipConfigurations: [for (configuration, index) in ipConfigurations: {
      name: configuration.key
      properties: {
        primary: (configuration.value.?isPrimary ?? (0 == index))
        privateIPAddress: (configuration.value.privateIpAddress.?value ?? null)
        privateIPAddressVersion: (configuration.value.privateIpAddress.?version ?? 'IPv4')
        privateIPAllocationMethod: (contains(configuration.value.privateIpAddress, 'value') ? 'Static' : 'Dynamic')
        publicIPAddress: (empty(configuration.value.?publicIpAddress ?? {}) ? null : { id: publicIpAddressesRef[index].id })
        subnet: { id: subnetsRef[index].id }
      }
    }]
    networkSecurityGroup: (isNetworkSecurityGroupNotEmpty ? { id: networkSecurityGroupRef.id } : null)
    nicType: 'Standard'
  }
  tags: tags
}
resource networkSecurityGroupRef 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (isNetworkSecurityGroupNotEmpty) {
  name: properties.networkSecurityGroup.name
  scope: resourceGroup((properties.networkSecurityGroup.?subscriptionId ?? subscriptionId), (properties.networkSecurityGroup.?resourceGroupName ?? resourceGroupName))
}
resource publicIpAddressesRef 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = [for configuration in ipConfigurations: {
  name: configuration.value.publicIpAddress.name
  scope: resourceGroup((configuration.value.publicIpAddress.?subscriptionId ?? subscriptionId), (configuration.value.publicIpAddress.?resourceGroupName ?? resourceGroupName))
}]
resource subnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for configuration in ipConfigurations: {
  name: '${configuration.value.privateIpAddress.subnet.virtualNetworkName}/${configuration.value.privateIpAddress.subnet.name}'
  scope: resourceGroup((configuration.value.privateIpAddress.?subscriptionId ?? subscriptionId), (configuration.value.privateIpAddress.?resourceGroupName ?? resourceGroupName))
}]
