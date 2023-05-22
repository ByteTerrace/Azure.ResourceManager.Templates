param guid string = newGuid()
param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}
param utcNow string = sys.utcNow()

var isAgentPlatformUpdateEnabled = ('automaticbyplatform' == toLower(operatingSystemPatchSettings.patchMode))
var isAvailabilitySetNotEmpty = !empty(properties.?availabilitySet ?? {})
var isBootDiagnosticsStorageAccountNotEmpty = !empty(properties.?bootDiagnostics.?storageAccount ?? {})
var isIdentitiesNotEmpty = !empty(properties.?identity ?? {})
var isLinux = ('linux' == toLower(operatingSystemType))
var isProximityPlacementGroupNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var isSecureBootEnabled = (properties.?isSecureBootEnabled ?? false)
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var isWindows = ('windows' == toLower(operatingSystemType))
var operatingSystemDisk = {
  caching: (properties.operatingSystem.?disk.?cachingMode ?? 'ReadWrite')
  createOption: (properties.operatingSystem.?disk.?createOption ?? 'FromImage')
  deleteOption: (properties.operatingSystem.?disk.?deleteOption ?? 'Delete')
  diffDiskSettings: (contains((properties.operatingSystem.?disk ?? {}), 'ephemeralPlacement') ? {
    option: 'Local'
    placement: properties.operatingSystem.disk.ephemeralPlacement
  } : null)
  diskSizeGB: (properties.operatingSystem.?disk.?sizeInGigabytes ?? null)
  managedDisk: {
    storageAccountType: (properties.operatingSystem.?disk.?storageAccountType ?? 'Standard_LRS')
  }
  name: (properties.operatingSystem.?disk.?name ?? '${name}-Disk00000')
  osType: operatingSystemType
  writeAcceleratorEnabled: (properties.operatingSystem.?disk.?isWriteAcceleratorEnabled ?? null)
}
var operatingSystemPatchSettings = {
  assessmentMode: (properties.operatingSystem.?patchSettings.?assessmentMode ?? 'AutomaticByPlatform')
  patchMode: (properties.operatingSystem.?patchSettings.?patchMode ?? 'AutomaticByPlatform')
}
var operatingSystemType = (properties.operatingSystem.?type ?? 'Windows')
var resourceGroupName = resourceGroup().name
var roleAssignments = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
})
var scripts = sort(map(range(0, length(properties.?scripts ?? [])), index => {
  blobPath: (properties.scripts[index].?blobPath ?? '')
  errorBlobPath: (properties.scripts[index].?errorBlobPath ?? '')
  errorBlobUri: (properties.scripts[index].?errorBlobUri ?? null)
  containerName: (properties.scripts[index].?containerName ?? null)
  index: index
  name: (properties.scripts[index].?name ?? index)
  outputBlobPath: (properties.scripts[index].?outputBlobPath ?? '')
  outputBlobUri: (properties.scripts[index].?outputBlobUri ?? null)
  parameters: (properties.scripts[index].?parameters ?? [])
  storageAccount: (contains(properties.scripts[index], 'storageAccount') ? union({
    id: resourceId('Microsoft.Storage/storageAccounts', properties.scripts[index].storageAccount.name)
  }, properties.scripts[index].storageAccount) : {})
  tags: (properties.scripts[index].?tags ?? tags)
  timeoutInSeconds: (properties.scripts[index].?timeoutInSeconds ?? null)
  uri: (properties.scripts[index].?uri ?? null)
  value: (properties.scripts[index].?value ?? null)
}), (x, y) => (x.index < y.index))
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
resource guestAttestation 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (isSecureBootEnabled) {
  location: location
  name: 'GuestAttestation'
  parent: virtualMachine
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.Security.${operatingSystemType}Attestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
  }
  tags: tags
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
resource runCommands 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [for script in scripts: {
  dependsOn: [ guestAttestation ]
  location: location
  name: script.name
  parent: virtualMachine
  properties: {
    asyncExecution: false
    errorBlobUri: (empty(script.errorBlobPath) ? script.errorBlobUri : format('{0}{1}/{2}?{3}', reference(script.storageAccount.id, '2022-09-01').primaryEndpoints.blob, script.containerName, script.errorBlobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
      canonicalizedResource: '/blob/${script.storageAccount.name}/${script.containerName}/${script.errorBlobPath}'
      signedExpiry: dateTimeAdd(utcNow, 'PT3H')
      signedPermission: 'rwacu'
      signedProtocol: 'https'
      signedResourceTypes: 'o'
      signedServices: 'b'
    }).accountSasToken))
    outputBlobUri: (empty(script.outputBlobPath) ? script.outputBlobUri : format('{0}{1}/{2}?{3}', reference(script.storageAccount.id, '2022-09-01').primaryEndpoints.blob, script.containerName, script.outputBlobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
      canonicalizedResource: '/blob/${script.storageAccount.name}/${script.containerName}/${script.outputBlobPath}'
      signedExpiry: dateTimeAdd(utcNow, 'PT3H')
      signedPermission: 'rwacu'
      signedProtocol: 'https'
      signedResourceTypes: 'o'
      signedServices: 'b'
    }).accountSasToken))
    protectedParameters: script.parameters
    source: {
      script: script.value
      scriptUri: (empty(script.blobPath) ? script.uri : format('{0}{1}/{2}?{3}', reference(script.storageAccount.id, '2022-09-01').primaryEndpoints.blob, script.containerName, script.blobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
        canonicalizedResource: '/blob/${script.storageAccount.name}/${script.containerName}/${script.blobPath}'
        signedExpiry: dateTimeAdd(utcNow, 'PT3H')
        signedPermission: 'r'
        signedProtocol: 'https'
        signedResourceTypes: 'o'
        signedServices: 'b'
      }).accountSasToken))
    }
    timeoutInSeconds: script.timeoutInSeconds
    treatFailureAsDeploymentFailure: true
  }
  tags: script.tags
}]
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  identity: (isIdentitiesNotEmpty ? {
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
        enabled: (properties.?bootDiagnostics.?isEnabled ?? false)
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
        enableVMAgentPlatformUpdates: isAgentPlatformUpdateEnabled
        patchSettings: {
          assessmentMode: operatingSystemPatchSettings.assessmentMode
          patchMode: operatingSystemPatchSettings.patchMode
        }
        provisionVMAgent: true
      } : null)
      windowsConfiguration: (isWindows ? {
        enableAutomaticUpdates: ('manual' != toLower(operatingSystemPatchSettings.patchMode))
        enableVMAgentPlatformUpdates: isAgentPlatformUpdateEnabled
        patchSettings: union(operatingSystemPatchSettings, {
          assessmentMode: operatingSystemPatchSettings.assessmentMode
          enableHotpatching: (properties.operatingSystem.?patchSettings.?isHotPatchingEnabled ?? isAgentPlatformUpdateEnabled)
          patchMode: operatingSystemPatchSettings.patchMode
        })
        provisionVMAgent: true
        timeZone: (properties.operatingSystem.?timeZone ?? null)
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
      osDisk: operatingSystemDisk
    }
  }
  tags: tags
}
