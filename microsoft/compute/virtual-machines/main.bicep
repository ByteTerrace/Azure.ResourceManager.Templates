param guid string = newGuid()
param location string = resourceGroup().location
param name string
param properties object
param tags object = {}
param utcNow string = sys.utcNow()

var isAvailabilitySetNotEmpty = !empty(properties.?availabilitySet ?? {})
var isBootDiagnosticsEnabled = (properties.?bootDiagnostics.?isEnabled ?? false)
var isBootDiagnosticsStorageAccountNotEmpty = !empty(properties.?bootDiagnostics.?storageAccount ?? {})
var isLinux = ('linux' == toLower(operatingSystemType))
var isProximityPlacementGroupNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var isSecureBootEnabled = (properties.?isSecureBootEnabled ?? false)
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var isWindows = ('windows' == toLower(operatingSystemType))
var operatingSystemType = (properties.operatingSystem.?type ?? 'Windows')
var resourceGroupName = resourceGroup().name
var roleAssignments = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
})
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(properties.?identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((properties.identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (properties.identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', properties.identity.userAssignedIdentities[index].name)
  index: index
}), (x, y) => (x.index < y.index))

resource availabilitySetRef 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (isAvailabilitySetNotEmpty) {
  name: properties.availabilitySet.name
  scope: resourceGroup((properties.availabilitySet.?subscriptionId ?? subscriptionId), (properties.availabilitySet.?resourceGroupName ?? resourceGroupName))
}
resource bootDiagnosticsStorageAccountRef 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (isBootDiagnosticsStorageAccountNotEmpty) {
  name: properties.bootDiagnostics.storageAccount.name
  scope: resourceGroup((properties.bootDiagnostics.?subscriptionId ?? subscriptionId), (properties.bootDiagnostics.?resourceGroupName ?? resourceGroupName))
}
resource networkInterfacesRef 'Microsoft.Network/networkInterfaces@2022-11-01' existing = [for interface in properties.networkInterfaces: {
  name: interface.name
  scope: resourceGroup((interface.?subscriptionId ?? subscriptionId), (interface.?resourceGroupName ?? resourceGroupName))
}]
resource proximityPlacementGroupRef 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (isProximityPlacementGroupNotEmpty) {
  name: properties.proximityPlacementGroup.name
  scope: resourceGroup((properties.proximityPlacementGroup.?subscriptionId ?? subscriptionId), (properties.proximityPlacementGroup.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignmentsRef 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: sys.guid(virtualMachine.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
  }
  scope: virtualMachine
}]
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  identity: (contains(properties, 'identity') ? {
    type: properties.identity.type
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty ? toObject(userAssignedIdentities, identity => identity.id, identity => {}) : null)
  } : null)
  location: location
  name: name
  properties: {
    additionalCapabilities: {
      hibernationEnabled: (properties.?isHibernationEnabled ?? null)
      ultraSSDEnabled: (properties.?isUltraSsdEnabled ?? null)
    }
    availabilitySet: (isAvailabilitySetNotEmpty ? { id: availabilitySetRef.id } : null)
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: isBootDiagnosticsEnabled
        storageUri: (isBootDiagnosticsStorageAccountNotEmpty ? bootDiagnosticsStorageAccountRef.properties.primaryEndpoints.blob : null)
      }
    }
    extensionsTimeBudget: 'PT1H30M'
    hardwareProfile: {
      vmSize: properties.sku.name
    }
    licenseType: (properties.?licenseType ?? null)
    networkProfile: {
      networkInterfaces: [for (interface, index) in properties.networkInterfaces: { id: networkInterfacesRef[index].id }]
    }
    osProfile: {
      adminPassword: (properties.?administrator.?password ?? '${guid}|${utcNow}!')
      adminUsername: (properties.?administrator.?name ?? uniqueString(toLower(name)))
      allowExtensionOperations: true
      computerName: (properties.?computerName ?? name)
      linuxConfiguration: (isLinux ? {
        enableVMAgentPlatformUpdates: true
        patchSettings: {
          assessmentMode: 'AutomaticByPlatform'
          patchMode: 'AutomaticByPlatform'
        }
      } : null)
      windowsConfiguration: (isWindows ? {
        enableAutomaticUpdates: true
        enableVMAgentPlatformUpdates: true
        patchSettings: {
          assessmentMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            bypassPlatformSafetyChecksOnUserSchedule: false
            rebootSetting: 'IfRequired'
          }
          enableHotpatching: true
          patchMode: 'AutomaticByPlatform'
        }
        provisionVMAgent: true
        timeZone: null
      } : null)
    }
    proximityPlacementGroup: (isProximityPlacementGroupNotEmpty ? { id: proximityPlacementGroupRef.id } : null)
    securityProfile: {
      encryptionAtHost: (properties.?isEncryptionAtHostEnabled ?? null)
      securityType: (isSecureBootEnabled ? 'TrustedLaunch' : null)
      uefiSettings: {
        secureBootEnabled: isSecureBootEnabled
        vTpmEnabled: isSecureBootEnabled
      }
    }
    storageProfile: {
      imageReference: (properties.?imageReference ?? null)
      osDisk: {
        caching: (properties.operatingSystem.?disk.?cachingMode ?? 'ReadWrite')
        createOption: (properties.operatingSystem.?disk.?createOption ?? 'FromImage')
        deleteOption: (properties.operatingSystem.?disk.?deleteOption ?? 'Delete')
        diffDiskSettings: (contains((properties.operatingSystem.?disk ?? {}), 'ephemeralPlacement') ? {
          option: 'Local'
          placement: properties.operatingSystem.disk.ephemeralPlacement
        } : null)
        diskSizeGB: (properties.operatingSystem.?disk.?sizeInGigabytes ?? null)
        managedDisk: {
          storageAccountType: (properties.operatingSystem.?disk.?sku.?name ?? 'Standard_LRS')
        }
        name: (properties.operatingSystem.?disk.?name ?? '${name}-00000')
        osType: operatingSystemType
        writeAcceleratorEnabled: (properties.operatingSystem.?disk.?isWriteAcceleratorEnabled ?? null)
      }
    }
  }
  tags: tags
}
