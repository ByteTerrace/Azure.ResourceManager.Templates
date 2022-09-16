@description('An array of availability zones that the Azure Redis Cache will be deployed within.')
param availabilityZones array = []
@description('Specifies the configuration of the Azure Redis Cache.')
param configuration object = {}
@description('An array of firewall rules that will be assigned to the Azure Redis Cache.')
param firewallRules array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Redis Cache.')
param identity object = {}
@description('Indicates whether the Azure Redis Cache is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Specifies the location in which the Azure Redis Cache resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Redis Cache.')
param name string
@description('Specifies the number of cluster shards that will be dedicated to the Azure Redis Cache.')
param numberOfShards int = 0
@description('Specifies the SKU of the Azure Redis Cache.')
param sku object = {
    capacity: 0
    family: 'C'
    name: 'Standard'
}
@description('An object that encapsulates the properties of the subnet that the Azure Redis Cache will be deployed within.')
param subnet object = {}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Redis Cache.')
param tags object = {}
@description('Specifies the version of the Azure Redis Cache.')
param version string = 'latest'

var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]
var zones = [for zone in availabilityZones: string(zone)]

resource cache 'Microsoft.Cache/redis@2022-05-01' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        enableNonSslPort: false
        minimumTlsVersion: '1.2'
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        redisConfiguration: empty(configuration) ? null : configuration
        redisVersion: version
        shardCount: ('premium' == toLower(sku.name)) ? numberOfShards : null
        sku: sku
        subnetId: empty(subnet) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, subnet).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
    }
    tags: tags
    zones: zones
}
resource firewallRulesCopy 'Microsoft.Cache/redis/firewallRules@2022-05-01' = [for rule in firewallRules: {
    name: rule.name
    parent: cache
    properties: {
        endIP: rule.endIpAddress
        startIP: rule.startIpAddress
    }
}]
