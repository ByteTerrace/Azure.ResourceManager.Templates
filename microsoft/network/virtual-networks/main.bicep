param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isDdosProtectionPlanNotEmpty = !empty(properties.?ddosProtectionPlan ?? {})
var resourceGroupName = resourceGroup().name
var roleAssignmentsTransform = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  resource: (empty(assignment.resource) ? null : {
    apiVersion: assignment.resource.apiVersion
    id: '/subscriptions/${(assignment.resource.?subscriptionId ?? subscriptionId)}/resourceGroups/${(assignment.resource.?resourceGroupName ?? resourceGroupName)}/providers/${assignment.resource.type}/${assignment.resource.path}'
    type: assignment.resource.type
  })
  roleDefinitionId: assignment.roleDefinitionId
})
var subnets = sort(map(items(properties.?subnets ?? {}), subnet => {
  addressPrefixes: subnet.value.addressPrefixes
  delegations: (subnet.value.?delegations ?? [])
  name: subnet.key
  natGateway: (subnet.value.?natGateway ?? {})
  networkSecurityGroup: (subnet.value.?networkSecurityGroup ?? {})
  privateEndpointNetworkPolicies: {
    isNetworkSecurityGroupEnabled: (subnet.value.?privateEndpointNetworkPolicies.?isNetworkSecurityGroupEnabled ?? true)
    isRouteTableEnabled: (subnet.value.?privateEndpointNetworkPolicies.?isRouteTableEnabled ?? true)
  }
  privateLinkServiceNetworkPolicies: {
    isEnabled: (subnet.value.?privateLinkServiceNetworkPolicies.?isEnabled ?? true)
  }
  routeTable: (subnet.value.?routeTable ?? {})
  serviceEndpoints: (subnet.value.?serviceEndpoints ?? {})
}), (x, y) => (x.name < y.name))
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
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(virtualNetwork.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: virtualNetwork
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
    ddosProtectionPlan: (isDdosProtectionPlanNotEmpty ? { id: ddosProtectionPlan.id } : null)
    dhcpOptions: {
      dnsServers: (properties.?dnsServers ?? [])
    }
    enableDdosProtection: isDdosProtectionPlanNotEmpty
    subnets: [for (subnet, index) in subnets: {
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
        natGateway: (empty(subnet.natGateway) ? null : { id: natGateways[index].id })
        networkSecurityGroup: (empty(subnet.networkSecurityGroup) ? null : { id: networkSecurityGroups[index].id })
        privateEndpointNetworkPolicies: ((subnet.privateEndpointNetworkPolicies.isNetworkSecurityGroupEnabled && subnet.privateEndpointNetworkPolicies.isRouteTableEnabled) ? 'Enabled' : (subnet.privateEndpointNetworkPolicies.isNetworkSecurityGroupEnabled ? 'NetworkSecurityGroupEnabled' : (subnet.privateEndpointNetworkPolicies.isRouteTableEnabled ? 'RouteTableEnabled' : 'Disabled')))
        privateLinkServiceNetworkPolicies: (subnet.privateLinkServiceNetworkPolicies.isEnabled ? 'Enabled' : 'Disabled')
        routeTable: (empty(subnet.routeTable) ? null : { id: routeTables[index].id })
        serviceEndpoints: map(items(subnet.serviceEndpoints), endpoint => {
          locations: (endpoint.value.?locations ?? null)
          service: endpoint.key
        })
      }
    }]
  }
  tags: tags
}
