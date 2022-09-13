@description('An object that encapsulates the properties of the Azure Application Insights that will be associated to the Azure Web Site.')
param applicationInsights object = {}
@description('An object that encapsulates the application settings that will be applied to the Azure Web Site.')
@secure()
param applicationSettings object = {}
@description('An object that encapsulates the cross-Origin resource sharing settings that will be applied to the Azure Web Site.')
param cors object = {}
@description('An object that encapsulates the function extension settings that will be applied to the Azure Web Site.')
param functionExtension object = {}
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Web Site.')
param identity object = {}
@description('Indicates whether the Azure Web Site will run in 32-bit mode.')
param is32BitModeEnabled bool = false
@description('Specifies the location in which the Azure Web Site resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Web Site.')
param name string
@description('An object that encapsulates the properties of the Azure Application Service Plan will be associated with the Azure Web Site.')
param servicePlan object

var applicationSettingsCopy = [for setting in items(applicationSettings): {
    name: setting.key
    value: setting.value
}]
var isApplicationInsightsEnabled = !empty(applicationInsights)
var isFunctionApplication = !empty(functionExtension)
var isWebApplication = !isFunctionApplication
var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource applicationInsightsReference 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsights)) {
    name: applicationInsights.name
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, applicationInsights).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, applicationInsights).resourceGroupName)
}
resource site 'Microsoft.Web/sites@2022-03-01' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    kind: (isFunctionApplication ? 'functionapp' : (isWebApplication ? 'app' : null))
    location: location
    name: name
    properties: {
        clientAffinityEnabled: false
        httpsOnly: true
        serverFarmId: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, servicePlan).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, servicePlan).resourceGroupName, 'Microsoft.Web/serverfarms', servicePlan.name)
        siteConfig: union({
            appSettings: union(isApplicationInsightsEnabled ? [
                {
                    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                    value: applicationInsightsReference.properties.InstrumentationKey
                }
                {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: applicationInsightsReference.properties.ConnectionString
                }
            ] : [], isFunctionApplication ? [
                {
                    name: 'AzureWebJobsStorage'
                    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountReference.name};AccountKey=${storageAccountReference.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
                }
                {
                    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
                    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountReference.name};AccountKey=${storageAccountReference.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
                }
            ] : [], applicationSettingsCopy)
            cors: {
                allowedOrigins: union(isFunctionApplication ? [ 'https://portal.azure.com' ] : [], union({ allowedOrigins: [] }, cors).allowedOrigins)
                supportCredentials: union({ isCredentialSupportEnabled: false }, cors).isCredentialSupportEnabled
            }
            ftpsState: 'FtpsOnly'
            netFrameworkVersion: 'v6.0'
            use32BitWorkerProcess: is32BitModeEnabled
        }, isWebApplication ? {
            alwaysOn: false
            metadata: [
                {
                    name: 'CURRENT_STACK'
                    value: 'dotnet'
                }
            ]
            phpVersion: 'OFF'
        } : {})
        virtualNetworkSubnetId: null
    }
    tags: isApplicationInsightsEnabled ? {
        'hidden-link: /app-insights-resource-id': resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, applicationInsights).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, applicationInsights).resourceGroupName, 'Microsoft.Insights/components', applicationInsights.name)
    } : null
}
resource storageAccountReference 'Microsoft.Storage/storageAccounts@2022-05-01' existing = if (isFunctionApplication) {
    name: functionExtension.storageAccount.name
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, functionExtension.storageAccount).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, functionExtension.storageAccount).resourceGroupName)
}
