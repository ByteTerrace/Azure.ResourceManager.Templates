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
      applicationSecurityGroups: [
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
      ]
      userManagedIdentities: [
        {
          name: 'byteterrace'
        }
      ]
      virtualMachines: [
        {
          diskEncryptionSet: {
            name: 'byteterrace'
          }
          identity: union({ type: 'SystemAssigned, UserAssigned' }, identity)
          imageReference: {
            offer: 'WindowsServer'
            publisher: 'MicrosoftWindowsServer'
            sku: '2022-datacenter-azure-edition-core-smalldisk'
            version: 'latest'
          }
          licenseType: 'Windows_Server'
          name: 'byteterrace'
          networkInterfaces: [
            {
              ipConfigurations: [
                {
                  privateIpAddress: {
                    subnet: {
                      name: 'AzureDevOpsAgents-0000'
                      virtualNetworkName: 'byteterrace'
                    }
                  }
                }
              ]
            }
          ]
          operatingSystem: {
            type: 'Windows'
          }
          scripts: [
            {
              blobPath: 'Invoke-GeneralizeAzureImageForWindows.ps1'
              containerName: 'scripts'
              parameters: {
                logFilePath: 'C:/WindowsAzure/ByteTerrace/main.log'
              }
              storageAccount: {
                name: 'byteterrace'
              }
            }
          ]
          sku: {
            name: 'Standard_D2d_v4'
          }
        }
      ]
    }
  }
}
