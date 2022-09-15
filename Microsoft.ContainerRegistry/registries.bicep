@description('An array of firewall rules that will be assigned to the Azure Container Registry.')
param firewallRules array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Container Registry.')
param identity object = {}
@description('Indicates whether the Azure Container Registry administrator user account is enabled.')
param isAdministratorAccountEnabled bool = false
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Container Registry.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the Azure Container Registry will allow anonymous pull requests.')
param isAnonymousPullEnabled bool = false
@description('Indicates whether dedicated data endpoints are enabled for the Azure Container Registry.')
param isDedicatedDataEndpointEnabled bool = false
@description('Indicates whether the Azure Container Registry is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the zone redundancy feature is enabled on the Azure Container Registry.')
param isZoneRedundancyEnabled bool = true
@description('Specifies the location in which the Azure Container Registry resource(s) will be deployed.')
param location string = resourceGroup().name
@description('Specifies the name of the Azure Container Registry.')
param name string
@description('Specifies the SKU of the Azure Container Registry.')
param sku object = {
    name: 'Premium'
}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Container Registry.')
param tags object = {}

var firewallRulesCopy = [for rule in firewallRules: {
    action: 'Allow'
    value: rule
}]
var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        adminUserEnabled: isAdministratorAccountEnabled
        anonymousPullEnabled: isAnonymousPullEnabled
        dataEndpointEnabled: isDedicatedDataEndpointEnabled
        networkRuleBypassOptions: isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None'
        networkRuleSet: ('premium' == toLower(sku.name)) ? {
            defaultAction: isPublicNetworkAccessEnabled ? 'Allow' : 'Deny'
            ipRules: firewallRulesCopy
        } : null
        policies: {
            azureADAuthenticationAsArmPolicy: {
                status: 'enabled'
            }
            exportPolicy: {
                status: 'enabled'
            }
            quarantinePolicy: {
                status: 'disabled'
            }
            retentionPolicy: {
                days: 14
                status: 'disabled'
            }
            softDeletePolicy: {
                retentionDays: 14
                status: 'disabled'
            }
            trustPolicy: {
                status: 'disabled'
                type: 'Notary'
            }
        }
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        zoneRedundancy: isZoneRedundancyEnabled ? 'Enabled' : 'Disabled'
    }
    sku: sku
    tags: tags
}
