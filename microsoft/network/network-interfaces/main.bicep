param location string = resourceGroup().location
param name string
param properties object
param tags object = {}

var isNetworkSecurityGroupNotEmpty = !empty(properties.?networkInterface ?? {})
var isPublicIpAddressNotEmpty = !empty(properties.?publicIpAddress ?? {})

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  location: location
  name: name
  properties: {
    dnsSettings: {
      dnsServers: (properties.?dnsServers ?? [])
    }
    disableTcpStateTracking: (contains(properties, 'isTcpStateTrackingEnabled') ? !properties.isTcpStateTrackingEnabled : null)
    enableAcceleratedNetworking: (properties.?isAcceleratedNetworkingEnabled ?? true)
    enableIPForwarding: (properties.?isIpForwardingEnabled ?? null)
    ipConfigurations: [for (configuration, index) in properties.ipConfigurations: {
      name: (configuration.?name ?? index)
      properties: {
        primary: (configuration.?isPrimary ?? (0 == index))
        privateIPAddress: (configuration.?privateIpAddress.?value ?? null)
        privateIPAddressVersion: (configuration.?privateIpAddress.?version ?? 'IPv4')
        privateIPAllocationMethod: (contains((configuration.?privateIpAddress ?? {}), 'value') ? 'Static' : 'Dynamic')
        publicIPAddress: (isPublicIpAddressNotEmpty ? { id: publicIpAddress.id } : null)
        subnet: { id: subnets[index].id }
      }
    }]
    networkSecurityGroup: (isNetworkSecurityGroupNotEmpty ? { id: networkSecurityGroup.id } : null)
    nicType: 'Standard'
  }
  tags: tags
}
resource networkSecurityGroup 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (isNetworkSecurityGroupNotEmpty) {
  name: properties.networkSecurityGroup.name
  scope: resourceGroup(properties.networkSecurityGroup.?resourceGroupName)
}
resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = if (isPublicIpAddressNotEmpty) {
  name: properties.publicIpAddress.name
  scope: resourceGroup(properties.publicIpAddress.?resourceGroupName)
}
resource subnets 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for configuration in properties.ipConfigurations: {
  name: '${configuration.privateIpAddress.subnet.virtualNetworkName}/${configuration.privateIpAddress.subnet.name}'
  scope: resourceGroup(configuration.privateIpAddress.subnet.?resourceGroup ?? resourceGroup().name)
}]
