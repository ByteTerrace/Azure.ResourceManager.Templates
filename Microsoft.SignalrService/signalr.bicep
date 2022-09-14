@description('An object that encapsulates the cross-Origin resource sharing settings that will be applied to the Azure SignalR Service.')
param cors object = {}
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure SignalR Service.')
param identity object = {}
@description('Indicates whether the Azure SignalR Service is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether shared keys are able to be used to access the Azure SignalR Service.')
param isSharedKeyAccessEnabled bool = false
@description('Specifies the location in which the Azure SignalR Service resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure SignalR Service.')
param name string
@description('An object that encapsulates the server-less settings that will be applied to the Azure SignalR Service.')
param serverless object = {}
@description('Specifies the SKU of the Azure SignalR Service.')
param sku object = {
    name: 'Standard_S1'
}

var isServerlessModeEnabled = !empty(serverless)
var upstreamTemplates = [for template in union({ upstreamTemplates: [] }, serverless).upstreamTemplates: {
    categoryPattern: union({ categoryPattern: '*' }, serverless).categoryPattern
    eventPattern: union({ eventPattern: '*' }, serverless).eventPattern
    hubPattern: union({ hubPattern: '*' }, serverless).hubPattern
    urlTemplate: serverless.urlTemplate
}]
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource signalRService 'Microsoft.SignalRService/signalR@2022-02-01' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        cors: {
            allowedOrigins: empty(union({ allowedOrigins: [] }, cors).allowedOrigins) ? [ '*' ] : cors.allowedOrigins
        }
        disableAadAuth: false
        disableLocalAuth: !isSharedKeyAccessEnabled
        features: [
            {
                flag: 'EnableConnectivityLogs'
                value: 'true'
            }
            {
                flag: 'ServiceMode'
                value: isServerlessModeEnabled ? 'Serverless' : 'Default'
            }
        ]
        networkACLs: {
            defaultAction: isPublicNetworkAccessEnabled ? 'Allow' : 'Deny'
        }
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        tls: {
            clientCertEnabled: false
        }
        upstream: isServerlessModeEnabled ? {
            templates: upstreamTemplates
        } : null
    }
    sku: sku
}
