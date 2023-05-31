@secure()
param allowedRdpIpAddress string
@secure()
param operatingSystemAdministrator object

var dnsResolversSubnet = {
  name: 'DnsResolvers'
  virtualNetworkName: virtualNetwork.name
}
var identity = {
  userAssignedIdentities: [ userManagedIdentity ]
}
var natGateway = {
  name: 'byteterrace'
}
var networkInterface = {
  name: 'byteterrace'
}
var networkSecurityGroup = {
  name: 'byteterrace'
}
var proximityPlacementGroup = {
  name: 'byteterrace'
}
var publicIpAddressPrefix = {
  name: 'byteterrace'
}
var routeTable = {
  name: 'byteterrace'
}
var userManagedIdentity = {
  name: 'byteterrace'
}
var virtualMachinesSubnet = {
  name: 'VirtualMachines'
  virtualNetworkName: virtualNetwork.name
}
var virtualNetwork = {
  name: 'byteterrace'
}

module main 'br/bytrc:byteterrace/resource-group-deployments:0.0.0' = {
  name: '${deployment().name}-main'
  params: {
    exclude: [
      'dnsResolvers'
    ]
    properties: {
      computeGalleries: {
        byteterrace: {
          imageDefinitions: {
            '2022-Datacenter-DevOpsAgent': {
              architecture: 'x64'
              generation: 'V2'
              identifier: {
                offer: 'WindowsServer'
                publisher: 'ByteTerrace'
                sku: '2022-Datacenter-DevOpsAgent'
              }
              isAcceleratedNetworkingSupported: true
              isHibernateSupported: false
              operatingSystem: {
                state: 'Generalized'
                type: 'Windows'
              }
              securityType: 'Standard'
            }
          }
        }
      }
      dnsResolvers: {
        byteterrace: {
          inboundEndpoints: {
            default: {
              privateIpAddress: {
                subnet: {
                  name: dnsResolversSubnet.name
                }
                value: '172.16.128.5'
              }
            }
          }
          virtualNetwork: virtualNetwork
        }
      }
      natGateways: {
        '${natGateway.name}': {
          publicIpAddresses: { 'byteterrace-nat': {} }
          sku: {
            name: 'Standard'
          }
        }
      }
      networkInterfaces: {
        '${networkInterface.name}': {
          ipConfigurations: {
            default: {
              privateIpAddress: {
                subnet: virtualMachinesSubnet
              }
              publicIpAddress: {
                name: 'byteterrace-vm'
              }
            }
          }
          isAcceleratedNetworkingEnabled: true
        }
      }
      networkSecurityGroups: {
        '${networkSecurityGroup.name}': {
          securityRules: {
            AllowRdpInbound: {
              access: 'Allow'
              destination: {
                addressPrefixes: [ 'VirtualNetwork' ]
                ports: [ '3389' ]
              }
              direction: 'Inbound'
              protocol: 'Tcp'
              source: {
                addressPrefixes: [ allowedRdpIpAddress ]
                ports: [ '*' ]
              }
            }
          }
        }
      }
      proximityPlacementGroups: {
        '${proximityPlacementGroup.name}': {}
      }
      publicIpAddresses: {
        'byteterrace-nat': {
          prefix: publicIpAddressPrefix
          sku: {
            name: 'Standard'
          }
          version: 'IPv4'
        }
        'byteterrace-vm': {
          prefix: publicIpAddressPrefix
          sku: {
            name: 'Standard'
          }
          version: 'IPv4'
        }
      }
      publicIpPrefixes: {
        '${publicIpAddressPrefix.name}': {
          length: 31
          sku: {
            name: 'Standard'
          }
          version: 'IPv4'
        }
      }
      routeTables: {
        '${routeTable.name}': {}
      }
      userManagedIdentities: {
        '${userManagedIdentity.name}': {}
      }
      virtualMachines: {
        byteterrace: {
          identity: identity
          imageReference: {
            gallery: {
              name: 'byteterrace'
            }
            name: '2022-Datacenter-DevOpsAgent'
            version: 'latest'
          }
          isEncryptionAtHostEnabled: true
          isGuestAgentEnabled: true
          isHibernationEnabled: false
          isSecureBootEnabled: false
          isUltraSsdEnabled: false
          isVirtualTrustedPlatformModuleEnabled: false
          licenseType: 'Windows_Server'
          networkInterfaces: {
            '${networkInterface.name}': {
              isExisting: true
            }
          }
          operatingSystem: {
            administrator: operatingSystemAdministrator
            disk: {
              sizeInGigabytes: 96
            }
            patchSettings: {
              assessmentMode: 'ImageDefault'
              isHotPatchingEnabled: false
              patchMode: 'Manual'
            }
            type: 'Windows'
          }
          proximityPlacementGroup: proximityPlacementGroup
          sku: {
            name: 'Standard_D2ds_v5'
          }
          spotSettings: {
            evictionPolicy: 'Delete'
          }
        }
      }
      virtualNetworks: {
        '${virtualNetwork.name}': {
          addressPrefixes: [
            '10.128.0.0/20'
            '172.16.128.0/20'
          ]
          subnets: {
            '${dnsResolversSubnet.name}': {
              addressPrefixes: [ '172.16.128.0/28' ]
              delegations: [ 'Microsoft.Network/dnsResolvers' ]
            }
            '${virtualMachinesSubnet.name}': {
              addressPrefixes: [ '10.128.0.0/24' ]
              natGateway: natGateway
              networkSecurityGroup: networkSecurityGroup
              routeTable: routeTable
            }
          }
        }
      }
    }
  }
}
