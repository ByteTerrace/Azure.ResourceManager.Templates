@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Service Bus Namespace.')
param identity object = {}
@description('Indicates whether the Azure Service Bus Namespace is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the zone redundancy feature is enabled on the Azure Service Bus Namespace.')
param isZoneRedundancyEnabled bool = true
@description('Specifies the location in which the Azure Service Bus Namespace resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Service Bus Namespace.')
param name string
@description('Specifies the SKU of the Azure Service Bus Namespace.')
param sku object = {
    name: 'Premium'
}

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource namespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        disableLocalAuth: true
        minimumTlsVersion: '1.2'
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        zoneRedundant: isZoneRedundancyEnabled
    }
    sku: sku
}
