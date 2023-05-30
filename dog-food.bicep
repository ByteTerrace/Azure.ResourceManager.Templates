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
      /*applicationSecurityGroups: [
        {
          name: 'byteterrace'
        }
      ]
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
              securityType: 'TrustedLaunch'
            }
          ]
          name: 'byteterrace'
        }
      ]
      containerRegistries: [
        {
          identity: identity
          isContentTrustPolicyEnabled: false
          isExportPolicyEnabled: true
          isPublicNetworkAccessEnabled: true
          isQuarantinePolicyEnabled: false
          name: 'byteterrace'
          sku: {
            name: 'Standard'
          }
        }
      ]
      diskEncryptionSets: [
        {
          encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
          identity: identity
          keyName: 'temp'
          keyVault: {
            name: 'byteterrace'
          }
          name: 'byteterrace'
        }
      ]
      keyVaults: [
        {
          isAllowTrustedMicrosoftServicesEnabled: true
          isPublicNetworkAccessEnabled: true
          name: 'byteterrace'
          sku: {
            name: 'Premium'
          }
          virtualNetworkRules: [
            {
              subnet: {
                name: 'AzureDevOpsAgents-0000'
                virtualNetworkName: 'byteterrace'
              }
            }
          ]
        }
      ]
      proximityPlacementGroups: [
        {
          name: 'byteterrace'
        }
      ]*/
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
            sku: '2022-datacenter-smalldisk'
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
    }
  }
}
