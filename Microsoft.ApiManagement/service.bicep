@description('An array of availability zones that the Azure API Management Service will be deployed within.')
param availabilityZones array = []
@description('')
param hostnameConfigurations array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure API Management Service.')
param identity object = {}
@description('Indicates whether the Azure API Management Service is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Specifies the location in which the Azure API Management Service resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure API Management Service.')
param name string
@description('An object that encapsulates the properties of the public IP addresse that the Azure API Management Service will be associated with.')
param publicIpAddress object = {}
@description('An object that encapsulates the properties of the publisher of the Azure API Management Service.')
param publisher object
@description('Specifies the SKU of the Azure API Management Service.')
param sku object = {
    capacity: 1
    name: 'Standard'
}
@description('An object that encapsulates the properties of the subnet that the Azure API Management Service will be deployed within.')
param subnet object = {}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure API Management Service.')
param tags object = {}

var identityType = union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
var isSubnetEmpty = empty(subnet)
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]
var zones = [for zone in availabilityZones: string(zone)]

resource service 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
    identity: {
        type: identityType
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        customProperties: {
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': string(false)
            'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': string(false)
        }
        hostnameConfigurations: [for configuration in hostnameConfigurations: {
            certificate: union({ certificate: null }, configuration).certificate
            certificateSource: !empty(union({ certificate: { keyVault: {} } }, configuration).certificate.keyVault) ? 'KeyVault' : null
            defaultSslBinding: union({ isPrimarySslBinding: (1 == length(hostnameConfigurations)) }, configuration).isPrimarySslBinding
            hostName: configuration.hostName
            identityClientId: empty(union({ certificate: { keyVault: {} } }, configuration).certificate.keyVault) ? null : reference(empty(union({
                userAssignedIdentity: {}
            }, configuration.certificate).userAssignedIdentity) ? extensionResourceId('${resourceGroup().id}/providers/Microsoft.ApiManagement/service/${name}', 'Microsoft.ManagedIdentity/identities', 'default') : resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, configuration.certificate.userAssignedIdentity).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, configuration.certificate.userAssignedIdentity).resourceGroupName, 'Microsoft.ManagedIdentity/userAssignedIdentities', configuration.certificate.userAssignedIdentity.name), '2022-01-31-preview').clientId
            keyVaultId: empty(union({ certificate: { keyVault: {} } }, configuration).certificate.keyVault) ? null : resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, configuration.keyVault).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, configuration.keyVault).resourceGroupName, 'Microsoft.KeyVault/vaults', configuration.keyVault.name)
            negotiateClientCertificate: union({ isClientCertificateNegotiationEnabled: false }, configuration).isClientCertificateNegotiationEnabled
            type: configuration.type
        }]
        publicIpAddressId: empty(publicIpAddress) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, publicIpAddress).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, publicIpAddress).resourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpAddress.name)
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        publisherEmail: publisher.email
        publisherName: publisher.name
        virtualNetworkConfiguration: isSubnetEmpty ? null : {
            subnetResourceId: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, subnet).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
        }
        virtualNetworkType: isSubnetEmpty ? 'None' : union({ virtualNetworkType: 'Internal' }, subnet).virtualNetworkType
    }
    sku: sku
    tags: tags
    zones: zones
}
