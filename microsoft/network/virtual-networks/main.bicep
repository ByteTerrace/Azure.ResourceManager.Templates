param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isDdosProtectionPlanNotEmpty = !empty(properties.?ddosProtectionPlan ?? {})
var resourceGroupName = resourceGroup().name
var subnets = sort(map(range(0, length(properties.?subnets ?? [])), index => {
  addressPrefixes: properties.subnets[index].addressPrefixes
  delegations: (properties.subnets[index].?delegations ?? [])
  index: index
  name: properties.subnets[index].name
  natGateway: (properties.subnets[index].?natGateway ?? {})
  networkSecurityGroup: (properties.subnets[index].?networkSecurityGroup ?? {})
  privateEndpointNetworkPolicies: {
    isNetworkSecurityGroupEnabled: (properties.subnets[index].?privateEndpointNetworkPolicies.?isNetworkSecurityGroupEnabled ?? true)
    isRouteTableEnabled: (properties.subnets[index].?privateEndpointNetworkPolicies.?isRouteTableEnabled ?? true)
  }
  privateLinkServiceNetworkPolicies: {
    isEnabled: (properties.subnets[index].?privateLinkServiceNetworkPolicies.?isEnabled ?? true)
  }
  routeTable: (properties.subnets[index].?routeTable ?? {})
  serviceEndpoints: (properties.subnets[index].?serviceEndpoints ?? [])
}), (x, y) => (x.index < y.index))
var subscriptionId = subscription().subscriptionId

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2022-11-01' existing = if (isDdosProtectionPlanNotEmpty) {
  name: properties.ddosProtectionPlan.name
  scope: resourceGroup((properties.ddosProtectionPlan.?subscriptionId ?? subscriptionId), (properties.ddosProtectionPlan.?resourceGroupName ?? resourceGroupName))
}
resource natGateways 'Microsoft.Network/natGateways@2022-11-01' existing = [for subnet in any(subnets): if (!empty(subnet.natGateway)) {
  name: subnet.natGateway.name
  scope: resourceGroup((subnet.natGateway.?subscriptionId ?? subscriptionId), (subnet.natGateway.?resourceGroupName ?? resourceGroupName))
}]
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2022-11-01' existing = [for subnet in any(subnets): if (!empty(subnet.networkSecurityGroup)) {
  name: subnet.networkSecurityGroup.name
  scope: resourceGroup((subnet.networkSecurityGroup.?subscriptionId ?? subscriptionId), (subnet.networkSecurityGroup.?resourceGroupName ?? resourceGroupName))
}]
resource routeTables 'Microsoft.Network/routeTables@2022-11-01' existing = [for subnet in any(subnets): if (!empty(subnet.routeTable)) {
  name: subnet.routeTable.name
  scope: resourceGroup((subnet.routeTable.?subscriptionId ?? subscriptionId), (subnet.routeTable.?resourceGroupName ?? resourceGroupName))
}]
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  location: location
  name: name
  properties: {
    addressSpace: {
      addressPrefixes: properties.addressPrefixes
    }
    ddosProtectionPlan: (isDdosProtectionPlanNotEmpty ? {
      id: ddosProtectionPlan.id
    } : null)
    dhcpOptions: {
      dnsServers: (properties.?dnsServers ?? [])
    }
    enableDdosProtection: isDdosProtectionPlanNotEmpty
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: ((1 == length(subnet.addressPrefixes)) ? first(subnet.addressPrefixes) : null)
        addressPrefixes: ((1 == length(subnet.addressPrefixes)) ? null : subnet.addressPrefixes)
        delegations: map(subnet.delegations, delegation => {
          name: replace(delegation, '/', '.')
          properties: {
            serviceName: delegation
          }
        })
        natGateway: (empty(subnet.natGateway) ? null : {
          id: natGateways[subnet.index].id
        })
        networkSecurityGroup: (empty(subnet.networkSecurityGroup) ? null : {
          id: networkSecurityGroups[subnet.index].id
        })
        privateEndpointNetworkPolicies: ((subnet.privateEndpointNetworkPolicies.isNetworkSecurityGroupEnabled && subnet.privateEndpointNetworkPolicies.isRouteTableEnabled) ? 'Enabled' : (subnet.privateEndpointNetworkPolicies.isNetworkSecurityGroupEnabled ? 'NetworkSecurityGroupEnabled' : (subnet.privateEndpointNetworkPolicies.isRouteTableEnabled ? 'RouteTableEnabled' : 'Disabled')))
        privateLinkServiceNetworkPolicies: (subnet.privateLinkServiceNetworkPolicies.isEnabled ? 'Enabled' : 'Disabled')
        routeTable: (empty(subnet.routeTable) ? null : {
          id: routeTables[subnet.index].id
        })
        serviceEndpoints: map(subnet.serviceEndpoints, endpoint => {
          locations: (endpoint.?locations ?? null)
          service: endpoint.name
        })
      }
    }]
  }
  tags: tags
}
