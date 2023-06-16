@secure()
param allowedRdpIpAddress string
@secure()
param operatingSystemAdministrator object
param projectName string

var computeGallery = {
  name: projectName
}
var dnsResolver = {
  name: projectName
}
var dnsResolversSubnet = {
  name: 'DnsResolvers'
  virtualNetworkName: virtualNetwork.name
}
var identity = {
  userAssignedIdentities: [ userManagedIdentity ]
}
var natGateway = {
  name: projectName
}
var networkInterface = {
  name: projectName
}
var networkSecurityGroup = {
  name: projectName
}
var proximityPlacementGroup = {
  name: projectName
}
var publicIpAddressPrefix = {
  name: projectName
}
var routeTable = {
  name: projectName
}
var storageAccount = {
  name: projectName
}
var userManagedIdentity = {
  name: projectName
}
var virtualMachinesSubnet = {
  name: 'VirtualMachines'
  virtualNetworkName: virtualNetwork.name
}
var virtualMachine = {
  name: projectName
}
var virtualMachineScaleSet = {
  name: projectName
}
var virtualNetwork = {
  name: projectName
}

module main 'br/bytrc:byteterrace/resource-group-deployments:0.0.0' = {
  name: '${deployment().name}-main'
  params: {
    exclude: [
      'dnsResolvers'
    ]
    properties: {
      computeGalleries: {
        '${computeGallery.name}': {
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
        '${dnsResolver.name}': {
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
          publicIpAddresses: { '${projectName}-nat': {} }
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
                name: '${projectName}-vm'
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
        '${projectName}-nat': {
          prefix: publicIpAddressPrefix
          sku: {
            name: 'Standard'
          }
          version: 'IPv4'
        }
        '${projectName}-vm': {
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
      storageAccounts: {
        '${storageAccount.name}': {
          accessTier: 'Hot'
          sku: {
            name: 'Standard_LRS'
          }
        }
      }
      userManagedIdentities: {
        '${userManagedIdentity.name}': {}
      }
      virtualMachines: {
        '${virtualMachine.name}': {
          identity: identity
          imageReference: {
            offer: 'WindowsServer'
            publisher: 'MicrosoftWindowsServer'
            sku: '2022-datacenter-smalldisk-g2'
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
              sizeInGigabytes: 150
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
            name: 'Standard_D8ds_v5'
          }
          spotSettings: {
            evictionPolicy: 'Delete'
          }
        }
      }
      virtualMachineScaleSets: {
        '${virtualMachineScaleSet.name}': {
          identity: identity
          imageReference: {
            gallery: computeGallery
            name: '2022-Datacenter-DevOpsAgent'
            version: 'latest'
          }
          isEncryptionAtHostEnabled: true
          isGuestAgentEnabled: true
          isHibernationEnabled: false
          isOverprovisioningEnabled: false
          isSecureBootEnabled: false
          isUltraSsdEnabled: false
          isVirtualTrustedPlatformModuleEnabled: false
          licenseType: 'Windows_Server'
          networkInterfaces: {
            '${networkInterface.name}': {
              ipConfigurations: {
                default: {
                  privateIpAddress: {
                    subnet: virtualMachinesSubnet
                  }
                  publicIpAddress: {
                    name: virtualMachineScaleSet.name
                  }
                }
              }
            }
          }
          operatingSystem: {
            administrator: operatingSystemAdministrator
            disk: {
              cachingMode: 'ReadOnly'
              ephemeralPlacement: 'ResourceDisk'
              sizeInGigabytes: 150
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
            name: 'Standard_D4ds_v5'
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
