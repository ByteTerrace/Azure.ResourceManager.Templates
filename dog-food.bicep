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
                addressPrefixes: [ '' ]
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
          name: 'byteterrace'
          networkInterfaces: [
            {
              ipConfigurations: [
                {
                  privateIpAddress: {
                    subnet: {
                      name: 'Test000'
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
              sizeInGigabytes: 256
            }
            patchSettings: {
              assessmentMode: 'ImageDefault'
              isHotPatchingEnabled: false
              patchMode: 'Manual'
            }
            type: 'Windows'
          }
          scripts: [
            {
              parameters:{
                logFilePath: 'C:/WindowsAzure/ByteTerrace/main.log'
              }
              timeoutInSeconds: 1800
              uri: 'https://byteterrace.blob.core.windows.net/scripts/Install-DevOpsAgentSoftware0.ps1'
            }
            {
              timeoutInSeconds: 300
              value: 'Restart-Computer -Force;'
            }
            {
              parameters:{
                logFilePath: 'C:/WindowsAzure/ByteTerrace/main.log'
              }
              timeoutInSeconds: 7200
              uri: 'https://byteterrace.blob.core.windows.net/scripts/Install-DevOpsAgentSoftware1.ps1'
            }
            {
              timeoutInSeconds: 300
              value: 'Restart-Computer -Force;'
            }
            {
              parameters:{
                logFilePath: 'C:/WindowsAzure/ByteTerrace/main.log'
              }
              timeoutInSeconds: 7200
              uri: 'https://byteterrace.blob.core.windows.net/scripts/Install-DevOpsAgentSoftware2.ps1'
            }
            {
              timeoutInSeconds: 300
              value: 'Restart-Computer -Force;'
            }
          ]
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
          addressPrefixes: [ '10.0.0.0/20' ]
          name: 'byteterrace'
          subnets: [
            {
              addressPrefixes: [ '10.0.0.0/24' ]
              name: 'Test000'
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
