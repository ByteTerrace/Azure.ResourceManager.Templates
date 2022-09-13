@description('An object that encapsulates the properties of the administrator that will be assigned to the Azure SQL Server.')
@secure()
param administrator object
@description('An array of firewall rules that will be assigned to the Azure SQL Server.')
param firewallRules array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure SQL Server.')
param identity object = {}
@description('Indicates whether trusted Microsoft services are allowed to access the Azure SQL Server.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the Azure SQL Server is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the SQL authentication is enabled on the Azure SQL Server.')
param isSqlAuthenticationEnabled bool = false
@description('Specifies the location in which the Azure SQL Server resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure SQL Server.')
param name string
@description('An array of virtual network rules that will be assigned to the Azure SQL Server.')
param virtualNetworkRules array = []

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource firewallRulesCopy 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = [for rule in firewallRules: {
    name: rule.name
    parent: server
    properties: {
        endIpAddress: rule.endIpAddress
        startIpAddress: rule.startIpAddress
    }
}]
resource server 'Microsoft.Sql/servers@2022-02-01-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        administratorLogin: isSqlAuthenticationEnabled ? administrator.name : null
        administratorLoginPassword: isSqlAuthenticationEnabled ? administrator.password : null
        administrators: empty(union({ login: '' }, administrator).login) ? null : {
            administratorType: 'activeDirectory'
            azureADOnlyAuthentication: (!isSqlAuthenticationEnabled || (empty(administrator.name) && empty(administrator.password)))
            login: administrator.login
            principalType: union({ principalType: 'User' }, administrator).principalType
            sid: administrator.objectId
            tenantId: union({ tenantId: tenant().tenantId }, administrator).tenantId
        }
        minimalTlsVersion: '1.2'
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        version: '12.0'
    }
}
resource trustedMicrosoftServicesfirewallRule 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = if (isAllowTrustedMicrosoftServicesEnabled) {
    name: 'AllowAllWindowsAzureIps'
    parent: server
    properties: {
        endIpAddress: '0.0.0.0'
        startIpAddress: '0.0.0.0'
    }
}
resource virtualNetworkRulesCopy 'Microsoft.Sql/servers/virtualNetworkRules@2022-02-01-preview' = [for rule in virtualNetworkRules: {
    name: rule.name
    parent: server
    properties: {
        ignoreMissingVnetServiceEndpoint: false
        virtualNetworkSubnetId: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, rule.subnet).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetwork/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
    }
}]
