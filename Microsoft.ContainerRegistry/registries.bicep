@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Container Registry.')
param identity object
@description('Indicates whether the Azure Container Registry administrator user account is enabled.')
param isAdministratorAccountEnabled bool
@description('Indicates whether trusted Azure services and resources are allowed to access the Azure Container Registry.')
param isAllowTrustedMicrosoftServicesEnabled bool
@description('Indicates whether the Azure Container Registry will allow anonymous pull requests.')
param isAnonymousPullEnabled bool
@description('Indicates whether dedicated data endpoints are enabled for the Azure Container Registry.')
param isDedicatedDataEndpointEnabled bool
@description('Indicates whether the Azure Container Registry is accessible from the internet.')
param isPublicNetworkAccessEnabled bool
@description('Indicates whether the Azure Container Registry will be zone redundant.')
param isZoneRedundant bool
@description('Specifies the location in which the Azure Container Registry resource(s) will be deployed.')
param location string
@maxLength(50)
@minLength(5)
@description('Specifies the name of the Azure Container Registry.')
param name string
@allowed([
    'Basic'
    'Premium'
    'Standard'
])
@description('Specifies the kind of the Azure Container Registry.')
param skuName string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Container Registry.')
param tags object

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: resourceId(union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName, 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
    identity: {
        type: union({
            type: (empty(userAssignedIdentities) ? 'None' : 'UserAssigned')
        }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        adminUserEnabled: isAdministratorAccountEnabled
        anonymousPullEnabled: isAnonymousPullEnabled
        dataEndpointEnabled: isDedicatedDataEndpointEnabled
        encryption: null
        networkRuleBypassOptions: (isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None')
        policies: null
        publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled')
        zoneRedundancy: (isZoneRedundant ? 'Enabled' : 'Disabled')
    }
    sku: {
        name: skuName
    }
    tags: tags
}
