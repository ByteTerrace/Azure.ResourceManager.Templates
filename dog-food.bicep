var identity = {
  userAssignedIdentities: [ userManagedIdentity ]
}
var userManagedIdentity = {
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
                  name: 'DnsResolvers'
                }
                value: '172.16.128.5'
              }
            }
          ]
          name: 'byteterrace'
          outboundEndpoints: []
          virtualNetwork: {
            name: 'byteterrace'
          }
        }
      ]
      networkSecurityGroups: [
        {
          name: 'byteterrace'
          securityRules: [
            {
              access: 'Allow'
              destination: {
                addressPrefixes: [ 'VirtualNetwork' ]
                ports: [ '3389' ]
              }
              direction: 'Inbound'
              name: 'AllowKittoesRdpInbound'
              protocol: 'Tcp'
              source: {
                addressPrefixes: [ '47.188.41.3' ]
                ports: [ '*' ]
              }
            }
          ]
        }
      ]
      userManagedIdentities: [
        {
          name: 'byteterrace'
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
                    subnet: {
                      name: 'VirtualMachines'
                      virtualNetworkName: 'byteterrace'
                    }
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
              sizeInGigabytes: 256
            }
            patchSettings: {
              assessmentMode: 'ImageDefault'
              isHotPatchingEnabled: false
              patchMode: 'Manual'
            }
            type: 'Windows'
          }
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
          name: 'byteterrace'
          subnets: [
            {
              addressPrefixes: [ '172.16.128.0/28' ]
              delegations: [ 'Microsoft.Network/dnsResolvers' ]
              name: 'DnsResolvers'
            }
            {
              addressPrefixes: [ '10.128.0.0/24' ]
              name: 'VirtualMachines'
              networkSecurityGroup: {
                name: 'byteterrace'
              }
              routeTable: {
                name: 'byteterrace'
              }
            }
          ]
        }
      ]
    }
  }
}
