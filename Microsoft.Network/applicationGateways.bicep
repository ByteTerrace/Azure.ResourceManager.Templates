@description('An array of availability zones that the Azure Application Gateway will be deployed within.')
param availabilityZones array = []
@description('An array of backend address pools that will be configured within the Azure Application Gateway.')
param backendAddressPools array
@description('An array of backend http settings that will be configured within the Azure Application Gateway.')
param backendHttpSettings array
@description('An object that encapsulates the front end properties of the Azure Application Gateway.')
param frontEnd object
@description('An array of http listeners that will be configured within the Azure Application Gateway.')
param httpListeners array
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Application Gateway.')
param identity object = {}
@description('Specifies the location in which the Azure Application Gateway resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Gateway.')
param name string
@description('An array of routing rules that will be configured within the Azure Application Gateway.')
param routingRules array = []
@description('Specifies the SKU of the Azure Application Gateway.')
param sku object = {
    capacity: 1
    name: 'Standard_v2'
    tier: 'Standard_v2'
}
@description('An object that encapsulates the properties of the subnet that the Azure Application Gateway will be deployed within.')
param subnet object

var frontEndPrivateIpAddress = union({ privateIpAddress: {} }, frontEnd).privateIpAddress
var frontEndPublicIpAddress = union({ publicIpAddress: {} }, frontEnd).publicIpAddress
var isV2Sku = contains([
    'standard_v2'
    'waf_v2'
], toLower(sku.name))
var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]
var zones = [for zone in availabilityZones: string(zone)]

resource applicationGateway 'Microsoft.Network/applicationGateways@2022-01-01' = {
    identity: isV2Sku ? {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    } : null
    location: location
    name: name
    properties: {
        backendAddressPools: [for pool in backendAddressPools: {
            name: pool.name
            properties: {
                backendAddresses: []
            }
        }]
        backendHttpSettingsCollection: [for entry in backendHttpSettings: {
            name: entry.name
            properties: {
                cookieBasedAffinity: union({ isCookieBasedAffinityEnabled: false }, entry).isCookieBasedAffinityEnabled ? 'Enabled' : 'Disabled'
                port: entry.port
                protocol: entry.protocol
            }
        }]
        enableHttp2: false
        frontendIPConfigurations: union((empty(frontEndPublicIpAddress) ? [] : [
            {
                name: 'appGwPublicFrontendIp'
                properties: {
                    publicIPAddress: {
                        id: resourceId(union({
                            subscriptionId: subscription().subscriptionId
                        }, frontEndPublicIpAddress).subscriptionId, union({
                            resourceGroupName: resourceGroup().name
                        }, frontEndPublicIpAddress).resourceGroupName, 'Microsoft.Network/publicIPAddresses', frontEndPublicIpAddress.name)
                    }
                }
            }
        ]), (empty(frontEndPrivateIpAddress) ? [] : [
            {
                name: 'appGwPrivateFrontendIp'
                properties: {
                    privateIPAllocationMethod: empty(union({ value: null }, frontEndPrivateIpAddress).value) ? 'Dynamic' : 'Static'
                    privateIPAddress: union({ value: null }, frontEndPrivateIpAddress).value
                    subnet: {
                        id: resourceId(union({
                            subscriptionId: subscription().subscriptionId
                        }, subnet).subscriptionId, union({
                            resourceGroupName: resourceGroup().name
                        }, subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', subnet.virtualNetworkName, subnet.name)
                    }
                }
            }
        ]))
        frontendPorts: [for port in frontEnd.ports: {
              name: string(port)
              properties: {
                  port: port
              }
        }]
        gatewayIPConfigurations: [
            {
                name: 'appGatewayIpConfig'
                properties: {
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
        httpListeners: [for listener in httpListeners: {
              name: listener.name
              properties: {
                  frontendIPConfiguration: {
                      id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, (union({ isPublic: empty(frontEndPrivateIpAddress) }, listener).isPublic ? 'appGwPublicFrontendIp' : 'appGwPrivateFrontendIp'))
                  }
                  frontendPort: {
                      id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, string(listener.port))
                  }
                  hostName: listener.hostName
                  protocol: listener.protocol
                  requireServerNameIndication: union({ isServerNameIndicationRequired: false }, listener).isServerNameIndicationRequired
              }
        }]
        requestRoutingRules: [for (rule, index) in routingRules: {
              name: rule.name
              properties: {
                  backendAddressPool: {
                      id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, rule.backendAddressPoolName)
                  }
                  backendHttpSettings: {
                      id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, rule.backendHttpSettingsCollectionName)
                  }
                  httpListener: {
                      id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, rule.httpListenerName)
                  }
                  priority: isV2Sku ? union({ priority: (index + 1) }, rule).priority : null
                  ruleType: union({ type: 'Basic' }, rule).type
              }
        }]
        sku: sku
    }
    zones: zones
}
