param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var resourceGroupName = resourceGroup().name
var securityRules = (properties.?securityRules ?? [])
var subscriptionId = subscription().subscriptionId

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  location: location
  name: name
  properties: {
    securityRules: [for (rule, index) in securityRules: {
      name: (rule.?name ?? '')
      properties: {
        access: rule.access
        description: (rule.?description ?? null)
        destinationAddressPrefix: ((1 == length(rule.destination.addressPrefixes)) ? first(rule.destination.addressPrefixes) : null)
        destinationAddressPrefixes: ((1 == length(rule.destination.addressPrefixes)) ? null : rule.destination.addressPrefixes)
        destinationApplicationSecurityGroups: (contains(rule.destination, 'applicationSecurityGroups') ? map(rule.destination.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        destinationPortRange: ((1 == length(rule.destination.ports)) ? first(rule.destination.ports) : null)
        destinationPortRanges: ((1 == length(rule.destination.ports)) ? null : rule.destination.ports)
        direction: rule.direction
        priority: ((1949 - length(securityRules)) + index)
        protocol: rule.protocol
        sourceAddressPrefix: ((1 == length(rule.source.addressPrefixes)) ? first(rule.source.addressPrefixes) : null)
        sourceAddressPrefixes: ((1 == length(rule.source.addressPrefixes)) ? null : rule.source.addressPrefixes)
        sourceApplicationSecurityGroups: (contains(rule.source, 'applicationSecurityGroups') ? map(rule.source.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        sourcePortRange: ((1 == length(rule.source.ports)) ? first(rule.source.ports) : null)
        sourcePortRanges: ((1 == length(rule.source.ports)) ? null : rule.source.ports)
      }
    }]
  }
  tags: tags
}
