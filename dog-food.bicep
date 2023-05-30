param ipAddress string

var dnsResolversSubnet = {
  name: 'DnsResolvers'
  virtualNetworkName: virtualNetwork.name
}
var identity = {
  userAssignedIdentities: [ userManagedIdentity ]
}
var networkSecurityGroup = {
  name: 'byteterrace'
}
var proximityPlacementGroup = {
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
    properties: {
      computeGalleries: [
        {
          imageDefinitions: [
            {
              architecture: 'x64'
              generation: 'V2'
              identifier: {
                offer: 'WindowsServer'
                publisher: 'ByteTerrace'
                sku: '2022-Datacenter-DevOpsAgent'
              }
              isAcceleratedNetworkingSupported: true
              isHibernateSupported: false
              name: '2022-Datacenter-DevOpsAgent'
              operatingSystem: {
                state: 'Generalized'
                type: 'Windows'
              }
              securityType: 'Standard'
            }
          ]
          name: 'byteterrace'
        }
      ]
      dnsResolvers: [
        {
          inboundEndpoints: [
            {
              privateIpAddress: {
                subnet: {
                  name: dnsResolversSubnet.name
                }
                value: '172.16.128.5'
              }
            }
          ]
          name: 'byteterrace'
          outboundEndpoints: []
          virtualNetwork: virtualNetwork
        }
      ]
      networkSecurityGroups: [
        {
          name: networkSecurityGroup.name
          securityRules: [
            {
              access: 'Allow'
              destination: {
                addressPrefixes: [ 'VirtualNetwork' ]
                ports: [ '3389' ]
              }
              direction: 'Inbound'
              name: 'AllowRdpInbound'
              protocol: 'Tcp'
              source: {
                addressPrefixes: [ ipAddress ]
                ports: [ '*' ]
              }
            }
          ]
        }
      ]
      proximityPlacementGroups: [
        {
          name: proximityPlacementGroup.name
        }
      ]
      routeTables: [
        {
          name: routeTable.name
        }
      ]
      userManagedIdentities: [
        {
          name: userManagedIdentity.name
        }
      ]
      virtualMachines: [
        {
          identity: union({ type: 'SystemAssigned, UserAssigned' }, identity)
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
          name: 'byteterrace'
          networkInterfaces: [
            {
              ipConfigurations: [
                {
                  privateIpAddress: {
                    subnet: virtualMachinesSubnet
                  }
                  publicIpAddress: {}
                }
              ]
            }
          ]
          operatingSystem: {
            disk: {
              cachingMode: 'ReadOnly'
              ephemeralPlacement: 'ResourceDisk'
              sizeInGigabytes: 300
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
      ]
      virtualNetworks: [
        {
          addressPrefixes: [
            '10.128.0.0/20'
            '172.16.128.0/20'
          ]
          name: virtualNetwork.name
          subnets: [
            {
              addressPrefixes: [ '172.16.128.0/28' ]
              delegations: [ 'Microsoft.Network/dnsResolvers' ]
              name: dnsResolversSubnet.name
            }
            {
              addressPrefixes: [ '10.128.0.0/24' ]
              name: virtualMachinesSubnet.name
              networkSecurityGroup: networkSecurityGroup
              routeTable: routeTable
            }
          ]
        }
      ]
    }
  }
}
