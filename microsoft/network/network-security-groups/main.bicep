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
    securityRules: [for (rule, index) in sort(items(securityRules), (x, y) => (x.key < y.key)): {
      name: rule.key
      properties: {
        access: rule.value.access
        description: (rule.value.?description ?? null)
        destinationAddressPrefix: ((1 == length(rule.value.destination.addressPrefixes)) ? first(rule.value.destination.addressPrefixes) : null)
        destinationAddressPrefixes: ((1 == length(rule.value.destination.addressPrefixes)) ? null : rule.value.destination.addressPrefixes)
        destinationApplicationSecurityGroups: (contains(rule.value.destination, 'applicationSecurityGroups') ? map(rule.value.destination.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        destinationPortRange: ((1 == length(rule.value.destination.ports)) ? first(rule.value.destination.ports) : null)
        destinationPortRanges: ((1 == length(rule.value.destination.ports)) ? null : rule.value.destination.ports)
        direction: rule.value.direction
        priority: ((1949 - length(securityRules)) + index)
        protocol: rule.value.protocol
        sourceAddressPrefix: ((1 == length(rule.value.source.addressPrefixes)) ? first(rule.value.source.addressPrefixes) : null)
        sourceAddressPrefixes: ((1 == length(rule.value.source.addressPrefixes)) ? null : rule.value.source.addressPrefixes)
        sourceApplicationSecurityGroups: (contains(rule.value.source, 'applicationSecurityGroups') ? map(rule.value.source.applicationSecurityGroups, group => {
          id: resourceId((group.?subscriptionId ?? subscriptionId), (group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
        }) : null)
        sourcePortRange: ((1 == length(rule.value.source.ports)) ? first(rule.value.source.ports) : null)
        sourcePortRanges: ((1 == length(rule.value.source.ports)) ? null : rule.value.source.ports)
      }
    }]
  }
  tags: tags
}
