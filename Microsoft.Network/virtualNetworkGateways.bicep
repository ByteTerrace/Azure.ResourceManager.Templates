@description('An object that encapsulates the properties of the client configuration that will be applied to the Azure Virtual Network Gateway')
param clientConfiguration object
@description('Specifies the generaton of the Azure Virtual Network Gateway.')
param generation int = 1
@description('An array of IP configurations that will be applied to the Azure Virtual Network Gateway.')
param ipConfigurations array
@description('Indicates whether active-active mode is enabled on the Azure Virtual Network Gateway.')
param isActiveActiveModeEnabled bool = false
@description('Specifies the location in which the Azure Virtual Network Gateway resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the mode of the Azure Virtual Network Gateway.')
param mode string = 'RouteBased'
@description('Specifies the name of the Azure Virtual Network Gateway.')
param name string
@description('Specifies the SKU of the Azure Virtual Network Gateway.')
param sku object = {
    name: 'Basic'
}
@description('Specifies the type of the Azure Virtual Network Gateway.')
param type string = 'Vpn'

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = {
    name: name
    location: location
    properties: {
        activeActive: isActiveActiveModeEnabled
        enableBgp: false
        gatewayType: type
        ipConfigurations: [for configuration in ipConfigurations: {
            name: union({ name: 'default' }, configuration).name
            properties: {
                privateIPAllocationMethod: union({ privateIpAddress: { allocationMethod: 'Dynamic' }}, configuration).privateIpAddress.allocationMethod
                publicIPAddress: {
                    id: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, configuration.publicIpAddress).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, configuration.publicIpAddress).resourceGroupName, 'Microsoft.Network/publicIPAddresses', configuration.publicIpAddress.name)
                }
                subnet: {
                    id: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, configuration.subnet).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, configuration.subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', configuration.subnet.virtualNetworkName, union({
                        name: 'GatewaySubnet'
                    }, configuration.subnet).name)
                }
            }
        }]
        sku: sku
        vpnClientConfiguration: {
            vpnAuthenticationTypes: clientConfiguration.authenticationTypes
            vpnClientAddressPool: {
                addressPrefixes: clientConfiguration.addressPrefixes
            }
            vpnClientProtocols: clientConfiguration.protocols
            vpnClientRootCertificates: [for certificate in clientConfiguration.rootCertificates: {
                name: certificate.name
                properties: {
                    publicCertData: certificate.publicCertificateData
                }
            }]
        }
        vpnGatewayGeneration: 'Generation${string(generation)}'
        vpnType: mode
    }
}
