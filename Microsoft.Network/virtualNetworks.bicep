@description('An array of address prefixes that will be reserved within the Azure Virtual Network.')
param addressPrefixes array
@description('An object that encapsulates the DDOS protection plan settings that will be applied to the Azure Virtual Network.')
param ddosProtectionPlan object = {}
@description('An array of DNS servers that the Azure Virtual Network will be associated with.')
param dnsServers array = []
@description('Specifies the location in which the Azure Virtual Network resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Virtual Network.')
param name string
@description('An array of subnets that will be configured within the Azure Virtual Network.')
param subnets array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
    location: location
    name: name
    properties: {
        addressSpace: {
            addressPrefixes: addressPrefixes
        }
        ddosProtectionPlan: empty(ddosProtectionPlan) ? null : {
            id: resourceId(union({
                resourceGroupName: resourceGroup().name
            }, ddosProtectionPlan).resourceGroupName, union({
                subscriptionId: subscription().subscriptionId
            }, ddosProtectionPlan).subscriptionId, 'Microsoft.Network/ddosProtectionPlans', ddosProtectionPlan.name)
        }
        dhcpOptions: {
            dnsServers: dnsServers
        }
        enableDdosProtection: !empty(ddosProtectionPlan)
        subnets: [for subnet in subnets: {
            name: subnet.name
            properties: {
                addressPrefix: (1 == length(subnet.addressPrefixes)) ? first(subnet.addressPrefixes) : null
                addressPrefixes: (1 < length(subnet.addressPrefixes)) ? subnet.addressPrefixes : null
                natGateway: empty(union({ natGateway: {} }, subnet).natGateway) ? null : {
                    id: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, subnet.natGateway).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, subnet.natGateway).resourceGroupName, 'Microsoft.Network/natGateways', subnet.natGateway.name)
                }
                networkSecurityGroup: empty(union({ networkSecurityGroup: {} }, subnet).networkSecurityGroup) ? null : {
                    id: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, subnet.networkSecurityGroup).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, subnet.networkSecurityGroup).resourceGroupName, 'Microsoft.Network/networkSecurityGroups', subnet.networkSecurityGroup.name)
                }
                privateEndpointNetworkPolicies: union({ isPrivateEndpointNetworkPoliciesEnabled: false }, subnet).isPrivateEndpointNetworkPoliciesEnabled ? 'Enabled' : 'Disabled'
                privateLinkServiceNetworkPolicies: union({ isPrivateLinkServiceNetworkPoliciesEnabled: false }, subnet).isPrivateLinkServiceNetworkPoliciesEnabled ? 'Enabled' : 'Disabled'
                routeTable: empty(union({ routeTable: {} }, subnet).routeTable) ? null : {
                    id: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, subnet.routeTable).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, subnet.routeTable).resourceGroupName, 'Microsoft.Network/routeTables', subnet.routeTable.name)
                }
            }
        }]
    }
}
