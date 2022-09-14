@description('An object that encapsulates the properties of the administrator that will be assigned to the Azure Virtual Machine.')
@secure()
param administrator object
@description('An object that encapsulates the properties of the Azure Availability Set that the Azure Virtual Machine will be deployed within.')
param availabilitySet object = {}
@description('An array of availability zones that the Azure Virtual Machine will be deployed within.')
param availabilityZones array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Virtual Machine.')
param identity object = {}
@description('An object that encapsulates the properties of the image that will be used to provision the Azure Virtual Machine.')
param imageReference object
@description('An object that encapsulates the properties of the Linux configuration that will be applied to the Azure Virtual Machine.')
param linuxConfiguration object = {}
@description('Specifies the location in which the Azure Virtual Machine resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Virtual Machine.')
param name string
@description('An array of network interfaces that will be associated to the Azure Virtual Machine.')
param networkInterfaces array = []
@description('An object that encapsulates the properties of the Azure Proximity Placement Group that the Azure Virtual Machine will be deployed within.')
param proximityPlacementGroup object = {}
@description('Specifies the SKU of the Azure Virtual Machine.')
param sku object
@description('An object that encapsulates the properties of the subnet that the Azure Virtual Machine will be deployed within.')
param subnet object = {}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Virtual Machine.')
param tags object = {}
@description('An object that encapsulates the properties of the Windows configuration that will be applied to the Azure Virtual Machine.')
param windowsConfiguration object = {}

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]
var zones = [for zone in availabilityZones: string(zone)]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
    location: location
    name: name
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    properties: {
        availabilitySet: empty(availabilitySet) ? null : {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, availabilitySet).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, availabilitySet).resourceGroupName, 'Microsoft.Compute/availabilitySets', availabilitySet.name)
        }
        extensionsTimeBudget: 'PT15M'
        hardwareProfile: {
            vmSize: sku.name
        }
        networkProfile: {
            networkApiVersion: empty(networkInterfaces) ? '2022-01-01' : null
            networkInterfaceConfigurations: empty(networkInterfaces) ? [{
                name: '${name}-nic'
                properties: {
                    deleteOption: 'Delete'
                    enableAcceleratedNetworking: true
                    enableFpga: false
                    enableIPForwarding: false
                    ipConfigurations: [
                        {
                            name: 'default'
                            properties: {
                                primary: true
                                privateIPAddressVersion: 'IPv4'
                                subnet: {
                                    id: resourceId(union({
                                        subscriptionId: subscription().subscriptionId
                                    }, subnet).subscriptionId, union({
                                        resourceGroupName: resourceGroup().name
                                    }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
                                }
                            }
                        }
                    ]
                    primary: true
                }
            }] : null
            networkInterfaces: [for networkInterface in networkInterfaces: {
                id: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, networkInterface).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, networkInterface).resourceGroupName, 'Microsoft.Network/networkInterfaces', networkInterface.name)
                properties: {
                    deleteOption: 'Detach'
                    primary: (1 == length(networkInterfaces))
                }
            }]
        }
        osProfile: {
            adminPassword: administrator.password
            adminUsername: administrator.userName
            allowExtensionOperations: true
            computerName: name
            linuxConfiguration: empty(linuxConfiguration) ? null : {
                disablePasswordAuthentication: false
                patchSettings: {
                    assessmentMode: 'ImageDefault'
                    patchMode: 'ImageDefault'
                }
                provisionVMAgent: linuxConfiguration.isVmAgentEnabled
            }
            windowsConfiguration: empty(windowsConfiguration) ? null : {
                patchSettings: {
                    assessmentMode: 'ImageDefault'
                    patchMode: 'ImageDefault'
                }
                provisionVMAgent: windowsConfiguration.isVmAgentEnabled
            }
        }
        proximityPlacementGroup: empty(proximityPlacementGroup) ? null : {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, proximityPlacementGroup).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, proximityPlacementGroup).resourceGroupName, 'Microsoft.Compute/proximityPlacementGroups', proximityPlacementGroup.name)
        }
        storageProfile: {
            dataDisks: []
            imageReference: empty(union({ galleryName: '' }, imageReference).galleryName) ? imageReference : {
                id: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, imageReference).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, imageReference).resourceGroupName, 'Microsoft.Compute/galleries/images/versions', imageReference.galleryName, imageReference.name, imageReference.version)
            }
            osDisk: {
                caching: 'ReadWrite'
                createOption: 'FromImage'
                deleteOption: 'Delete'
                name: '${name}-osdisk'
                osType: empty(windowsConfiguration) ? 'Linux' : 'Windows'
                writeAcceleratorEnabled: false
            }
        }
    }
    tags: tags
    zones: zones
}
