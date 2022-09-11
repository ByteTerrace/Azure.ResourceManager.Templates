@description('An array of application security groups that the Azure Private Endpoint will be associated with.')
param applicationSecurityGroups array
@description('Specifies the location in which the Azure Private Endpoint resource(s) will be deployed.')
param location string
@description('Specifies the name of the Azure Private Endpoint.')
param name string
@description('An object that encapsulates the properties of the resource that the Azure Private Endpoint will be associated with.')
param resource object
@description('An object that encapsulates the properties of the subnet that the Azure Private Endpoint will be associated with.')
param subnet object

var knownTypeToDnsZoneConfigurationMap = {
    'Microsoft.KeyVault/vaults': [ { name: 'privatelink.vaultcore.azure.net' } ]
    'Microsoft.Storage/storageAccounts/blobServices': [ { name: 'privatelink.blob.${environment().suffixes.storage}' } ]
    'Microsoft.Storage/storageAccounts/fileServices': [ { name: 'privatelink.file.${environment().suffixes.storage}' } ]
    'Microsoft.Storage/storageAccounts/queueServices': [ { name: 'privatelink.queue.${environment().suffixes.storage}' } ]
    'Microsoft.Storage/storageAccounts/staticWebsite': [ { name: 'privatelink.web.${environment().suffixes.storage}' } ]
    'Microsoft.Storage/storageAccounts/tableServices': [ { name: 'privatelink.table.${environment().suffixes.storage}' } ]
}
var knownTypeToGroupIdMap = {
    'Microsoft.KeyVault/vaults': [ 'vault' ]
    'Microsoft.Storage/storageAccounts/blobServices': [ 'blob' ]
    'Microsoft.Storage/storageAccounts/fileServices': [ 'file' ]
    'Microsoft.Storage/storageAccounts/queueServices': [ 'queue' ]
    'Microsoft.Storage/storageAccounts/staticWebsite': [ 'web' ]
    'Microsoft.Storage/storageAccounts/tableServices': [ 'table' ]
}

var privateDnsZoneGroups = [{ dnsZoneConfigurations: knownTypeToDnsZoneConfigurationMap[format('{0}{1}', resource.type, ((1 == length(split(resource.name, '/')) ? '' : (2 == length(split(resource.name, '/'))) ? '/${last(split(resource.name, '/'))}' : '')))] }]
var privateLinkServiceConnections = [{ resource: resource }]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
    location: location
    name: name
    properties: {
        applicationSecurityGroups: [for group in applicationSecurityGroups: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, group).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, group).resourceGroupName, 'Microsoft.Network/applicationSecurityGroups', group.name)
        }]
        privateLinkServiceConnections: [for connection in privateLinkServiceConnections: {
            name: union({ name: 'default' }, connection).name
            properties: {
                groupIds: knownTypeToGroupIdMap[format('{0}{1}', connection.resource.type, ((1 == length(split(connection.resource.name, '/')) ? '' : ((2 == length(split(connection.resource.name, '/'))) ? '/${last(split(connection.resource.name, '/'))}' : ''))))]
                privateLinkServiceId: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, connection.resource).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, connection.resource).resourceGroupName, connection.resource.type, first(split(connection.resource.name, '/')))
            }
        }]
        subnet: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, subnet).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
        }
    }
}

resource privateDnsZoneGroupsCopy 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = [for group in privateDnsZoneGroups: {
    name: union({ name: 'default' }, group).name
    parent: privateEndpoint
    properties: {
        privateDnsZoneConfigs: [for configuration in group.dnsZoneConfigurations: {
            name: configuration.name
            properties: {
                privateDnsZoneId: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, configuration).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, configuration).resourceGroupName, 'Microsoft.Network/privateDnsZones', configuration.name)
            }
        }]
    }
}]
