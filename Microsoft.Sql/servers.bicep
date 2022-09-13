@description('An object that encapsulates the properties of the administrator that will be assigned to the Azure SQL Server.')
@secure()
param administrator object = {}
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure SQL Server.')
param identity object = {}
@description('Indicates whether the Azure SQL Server is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Specifies the location in which the Azure SQL Server resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure SQL Server.')
param name string

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource server 'Microsoft.Sql/servers@2022-02-01-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        administratorLogin: administrator.name
        administratorLoginPassword: administrator.password
        minimalTlsVersion: '1.2'
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        restrictOutboundNetworkAccess: 'Disabled'
        version: '12.0'
    }
}
