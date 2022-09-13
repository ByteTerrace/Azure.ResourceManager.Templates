@description('An array of DNS servers that the Azure Network Interface will be configured to use.')
param dnsServers array = []
@description('An array of IP configurations that will be applied to the Azure Network Interface.')
param ipConfigurations array
@description('Indicates whether the accelerated networking feature is enabled on the Azure Network Interface.')
param isAcceleratedNetworkingEnabled bool = true
@description('Indicates whether the IP forwarding feature is enabled on the Azure Network Interface.')
param isIpForwardingEnabled bool = false
@description('Specifies the location in which the Azure Network Interface resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Network Interface.')
param name string
@description('An object that encapsulates the properties of the Azure Network Security Group that this Azure Network Interface will be associated with.')
param networkSecurityGroup object = {}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-01-01' = {
    location: location
    name: name
    properties: {
        dnsSettings: {
            dnsServers: dnsServers
        }
        enableAcceleratedNetworking: isAcceleratedNetworkingEnabled
        enableIPForwarding: isIpForwardingEnabled
        ipConfigurations: [for (configuration, index) in ipConfigurations: {
            name: union({ name: (1 == length(ipConfigurations)) ? 'default': string(index) }, configuration).name
            properties: {
                primary: union({ isPrimary: (1 == length(ipConfigurations)) }, configuration).isPrimary
                privateIPAddress: union({ value: null }, configuration.privateIpAddress).value
                privateIPAddressVersion: union({ version: 'IPv4' }, configuration.privateIpAddress).version
                privateIPAllocationMethod: empty(union({ value: null }, configuration.privateIpAddress).value) ? 'Dynamic' : 'Static'
                publicIPAddress: empty(union({ publicIpAddress: {} }, configuration).publicIpAddress) ? null : {
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
                    }, configuration.subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', configuration.subnet.virtualNetworkName, configuration.subnet.name)
                }
            }
        }]
        networkSecurityGroup: empty(networkSecurityGroup) ? null : {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, networkSecurityGroup).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, networkSecurityGroup).resourceGroupName, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroup.name)
        }
    }
}
