param guid string = newGuid()
param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}
param utcNow string = sys.utcNow()

var administrator = {
  name: (properties.operatingSystem.?administrator.?name ?? uniqueString(toLower(name)))
  password: (properties.operatingSystem.?administrator.?password ?? '${guid}|${utcNow}!')
}
var certificates = items(properties.?certificates ?? {})
var identity = (properties.?identity ?? {})
var isAgentPlatformUpdateEnabled = ('automaticbyplatform' == toLower(operatingSystemPatchSettings.patchMode))
var isAutomaticShutdownNotEmpty = !empty(properties.?automaticShutdown ?? {})
var isAvailabilitySetNotEmpty = !empty(properties.?availabilitySet ?? {})
var isBootDiagnosticsStorageAccountNotEmpty = !empty(properties.?bootDiagnostics.?storageAccount ?? {})
var isCapacityReservationGroupNotEmpty = !empty(properties.?capacityReservationGroup ?? {})
var isCertificatesNotEmpty = !empty(certificates)
var isComputeGalleryNotEmpty = !empty(properties.?imageReference.?gallery ?? {})
var isDiskEncryptionSetNotEmpty = !empty(properties.?diskEncryptionSet ?? {})
var isGuestAgentEnabled = (properties.?isGuestAgentEnabled ?? true)
var isGuestAttestationEnabled = (properties.?isGuestAttestationEnabled ?? (isSecureBootEnabled && isVirtualTrustedPlatformModuleEnabled))
var isIdentityNotEmpty = !empty(identity)
var isLinux = ('linux' == toLower(properties.operatingSystem.type))
var isProximityPlacementGroupNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var isSecureBootEnabled = (properties.?isSecureBootEnabled ?? true)
var isSpotSettingsNotEmpty = !empty(properties.?spotSettings ?? {})
var isSystemAssignedIdentityEnabled = contains((identity.?type ?? ''), 'systemassigned')
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var isVirtualMachineScaleSetNotEmpty = !empty(properties.?virtualMachineScaleSet ?? {})
var isVirtualTrustedPlatformModuleEnabled = (properties.?isVirtualTrustedPlatformModuleEnabled ?? true)
var isWindows = ('windows' == toLower(properties.operatingSystem.type))
var operatingSystemPatchSettings = {
  assessmentMode: (properties.operatingSystem.?patchSettings.?assessmentMode ?? 'AutomaticByPlatform')
  patchMode: (properties.operatingSystem.?patchSettings.?patchMode ?? 'AutomaticByPlatform')
}
var resourceGroupName = resourceGroup().name
var scripts = sort(map(range(0, length(properties.?scripts ?? [])), index => {
  blobPath: (properties.scripts[index].?blobPath ?? '')
  containerName: (properties.scripts[index].?containerName ?? null)
  errorBlobPath: (properties.scripts[index].?errorBlobPath ?? '')
  errorBlobUri: (properties.scripts[index].?errorBlobUri ?? null)
  index: index
  name: (properties.scripts[index].?name ?? index)
  outputBlobPath: (properties.scripts[index].?outputBlobPath ?? '')
  outputBlobUri: (properties.scripts[index].?outputBlobUri ?? null)
  parameters: map(items(properties.scripts[index].?parameters ?? {}), parameter => {
    name: parameter.key
    value: parameter.value
  })
  storageAccount: (contains(properties.scripts[index], 'storageAccount') ? union({
    id: resourceId('Microsoft.Storage/storageAccounts', properties.scripts[index].storageAccount.name)
  }, properties.scripts[index].storageAccount) : {})
  tags: (properties.scripts[index].?tags ?? tags)
  timeoutInSeconds: (properties.scripts[index].?timeoutInSeconds ?? null)
  uri: (properties.scripts[index].?uri ?? null)
  value: (properties.scripts[index].?value ?? null)
}), (x, y) => (x.index < y.index))
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))

resource automaticShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (isAutomaticShutdownNotEmpty) {
  location: location
  name: 'shutdown-computevm-${name}'
  properties: {
    dailyRecurrence: (properties.automaticShutdown.?dailyRecurrence ?? null)
    hourlyRecurrence: (properties.automaticShutdown.?hourlyRecurrence ?? null)
    notificationSettings: (contains(properties.automaticShutdown, 'notificationSettings') ? {
      emailRecipient: (contains(properties.automaticShutdown.notificationSettings, 'emailRecipients') ? join(properties.automaticShutdown.notificationSettings.emailRecipients, ';') : null)
      webhookUrl: (properties.automaticShutdown.notificationSettings.?webhookUrl ?? null)
    } : null)
    status: ((properties.automaticShutdown.?isEnabled ?? isAutomaticShutdownNotEmpty) ? 'Enabled' : 'Disabled')
    targetResourceId: virtualMachine.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: properties.automaticShutdown.timeZone
    weeklyRecurrence: (properties.automaticShutdown.?weeklyRecurrence ?? null)
  }
  tags: tags
}
resource availabilitySetRef 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (isAvailabilitySetNotEmpty) {
  name: properties.availabilitySet.name
  scope: resourceGroup((properties.availabilitySet.?subscriptionId ?? subscriptionId), (properties.availabilitySet.?resourceGroupName ?? resourceGroupName))
}
resource bootDiagnosticsStorageAccountRef 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (isBootDiagnosticsStorageAccountNotEmpty) {
  name: properties.bootDiagnostics.storageAccount.name
  scope: resourceGroup((properties.bootDiagnostics.?subscriptionId ?? subscriptionId), (properties.bootDiagnostics.?resourceGroupName ?? resourceGroupName))
}
resource capacityReservationGroupRef 'Microsoft.Compute/capacityReservationGroups@2023-03-01' existing = if (isCapacityReservationGroupNotEmpty) {
  name: properties.capacityReservationGroup.name
  scope: resourceGroup((properties.capacityReservationGroup.?subscriptionId ?? subscriptionId), (properties.capacityReservationGroup.?resourceGroupName ?? resourceGroupName))
}
resource certificatesRef 'Microsoft.KeyVault/vaults/secrets@2023-02-01' existing = [for certificate in certificates: {
  name: '${certificate.value.keyVault.name}/${certificate.key}'
  scope: resourceGroup((certificate.value.keyVault.?subscriptionId ?? subscriptionId), (certificate.value.keyVault.?resourceGroupName ?? resourceGroupName))
}]
resource computeGalleryImageRef 'Microsoft.Compute/galleries/images/versions@2022-03-03' existing = if (isComputeGalleryNotEmpty) {
  name: '${properties.imageReference.gallery.name}/${properties.imageReference.name}/${(properties.imageReference.?version ?? 'latest')}'
  scope: resourceGroup((properties.imageReference.gallery.?subscriptionId ?? subscriptionId), (properties.imageReference.gallery.?resourceGroupName ?? resourceGroupName))
}
resource diskEncryptionSetRef 'Microsoft.Compute/diskEncryptionSets@2022-07-02' existing = if (isDiskEncryptionSetNotEmpty) {
  name: properties.diskEncryptionSet.name
  scope: resourceGroup((properties.diskEncryptionSet.?subscriptionId ?? subscriptionId), (properties.diskEncryptionSet.?resourceGroupName ?? resourceGroupName))
}
resource guestAttestation 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (isGuestAttestationEnabled) {
  dependsOn: [ keyVaultIntegration ]
  location: location
  name: 'GuestAttestation'
  parent: virtualMachine
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.Security.${properties.operatingSystem.type}Attestation'
    type: 'GuestAttestation'
    typeHandlerVersion: (isWindows ? '1.0' : (isLinux ? '1.0' : null))
  }
  tags: tags
}
resource keyVaultIntegration 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (isCertificatesNotEmpty) {
  location: location
  name: 'KeyVault'
  parent: virtualMachine
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.KeyVault'
    settings: {
      authenticationSettings: {
        msiClientId: (isSystemAssignedIdentityEnabled ? systemAssignedIdentityRef.properties.clientId : (isUserAssignedIdentitiesNotEmpty ? userAssignedIdentitiesRef[0].properties.clientId : null))
        msiEndpoint: 'http://169.254.169.254/metadata/identity/oauth2/token'
      }
      secretsManagementSettings: {
        linkOnRenewal: (isWindows ? true : null)
        observedCertificates: [for (certificate, index) in certificates: (isWindows ? {
          accounts: (certificate.value.?accounts ?? null)
          certificateStoreLocation: (certificate.value.?storeLocation ?? 'CurrentUser')
          certificateStoreName: (certificate.value.?storeName ?? 'MY')
          keyExportable: (certificate.value.?isExportable ?? false)
          url: certificatesRef[index].properties.secretUri
        } : certificatesRef[index].properties.secretUri)]
        requireInitialSync: true
      }
    }
    suppressFailures: false
    type: 'KeyVaultFor${properties.operatingSystem.type}'
    typeHandlerVersion: (isWindows ? '3.1' : (isLinux ? '2.2' : null))
  }
  tags: tags
}
resource networkInterfacesRef 'Microsoft.Network/networkInterfaces@2022-11-01' existing = [for interface in properties.networkInterfaces: {
  name: interface.name
  scope: resourceGroup((interface.?subscriptionId ?? subscriptionId), (interface.?resourceGroupName ?? resourceGroupName))
}]
resource proximityPlacementGroupRef 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' existing = if (isProximityPlacementGroupNotEmpty) {
  name: properties.proximityPlacementGroup.name
  scope: resourceGroup((properties.proximityPlacementGroup.?subscriptionId ?? subscriptionId), (properties.proximityPlacementGroup.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
}): {
  name: sys.guid(virtualMachine.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
  }
  scope: virtualMachine
}]
@batchSize(1)
resource runCommands 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [for script in scripts: {
  dependsOn: [
    guestAttestation
    keyVaultIntegration
  ]
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
    runAsPassword: administrator.password
    runAsUser: administrator.name
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
resource systemAssignedIdentityRef 'Microsoft.ManagedIdentity/identities@2023-01-31' existing = if (isSystemAssignedIdentityEnabled) {
  name: 'default'
  scope: virtualMachine
}
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.value.name
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  identity: (isIdentityNotEmpty ? {
    type: ((isUserAssignedIdentitiesNotEmpty && !contains(identity, 'type')) ? 'UserAssigned' : identity.type)
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
    capacityReservation: (isCapacityReservationGroupNotEmpty ? { capacityReservationGroup: { id: capacityReservationGroupRef.id } } : null)
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: (properties.?bootDiagnostics.?isEnabled ?? isBootDiagnosticsStorageAccountNotEmpty)
        storageUri: (isBootDiagnosticsStorageAccountNotEmpty ? bootDiagnosticsStorageAccountRef.properties.primaryEndpoints.blob : null)
      }
    }
    evictionPolicy: (isSpotSettingsNotEmpty ? properties.spotSettings.evictionPolicy : null)
    billingProfile: (isSpotSettingsNotEmpty ? {
      maxPrice: (properties.spotSettings.?maximumPrice ?? -1)
    } : null)
    extensionsTimeBudget: 'PT47M'
    hardwareProfile: {
      vmSize: properties.sku.name
    }
    licenseType: (properties.?licenseType ?? null)
    networkProfile: {
      networkApiVersion: ((0 != length(filter(properties.networkInterfaces, interface => !contains(interface, 'name')))) ? '2020-11-01' : null)
      networkInterfaceConfigurations: [for (interface, index) in filter(properties.networkInterfaces, interface => !contains(interface, 'name')): {
        name: '${name}-Nic-${padLeft(index, 5, '0')}'
        properties: {
          deleteOption: 'Delete'
          disableTcpStateTracking: !(interface.?isTcpStateTrackingEnabled ?? true)
          dnsSettings: {
            dnsServers: (interface.?dnsServers ?? [])
          }
          dscpConfiguration: (contains(interface, 'dscpConfiguration') ? {
            id: resourceId((interface.dscpConfiguration.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/dscpConfigurations', interface.dscpConfiguration.name)
          } : null)
          enableAcceleratedNetworking: (interface.?isAcceleratedNetworkingEnabled ?? true)
          enableFpga: (interface.?isFpgaNetworkingEnabled ?? null)
          enableIPForwarding: (interface.?isIpForwardingEnabled ?? false)
          ipConfigurations: map(range(0, length(interface.ipConfigurations)), index => {
            name: (interface.ipConfigurations[index].?name ?? index)
            properties: {
              applicationGatewayBackendAddressPools: flatten(map((interface.ipConfigurations[index].?applicationGateways ?? []), gateway => map(gateway.backEndAddressPoolNames, name => {
                id: resourceId((gateway.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationGateways/backendAddressPools', gateway.name, name)
              })))
              applicationSecurityGroups: map((interface.ipConfigurations[index].?applicationSecurityGroups ?? []), group => {
                id: resourceId((group.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.name)
              })
              loadBalancerBackendAddressPools: flatten(map((interface.ipConfigurations[index].?loadBalancers ?? []), loadBalancer => map(loadBalancer.backEndAddressPoolNames, name => {
                id: resourceId((loadBalancer.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/loadBalancers/backendAddressPools', loadBalancer.name, name)
              })))
              primary: (interface.ipConfigurations[index].?isPrimary ?? ((0 == index) && (0 == length(filter(interface.ipConfigurations, configuration => contains(configuration, 'isPrimary'))))))
              privateIPAddressVersion: (interface.ipConfigurations[index].privateIpAddress.?version ?? 'IPv4')
              publicIPAddressConfiguration: (contains(interface.ipConfigurations[index], 'publicIpAddress') ? {
                name: '${name}-Pip-${padLeft(index, 5, '0')}'
                properties: {
                  deleteOption: 'Delete'
                  dnsSettings: (contains(interface.ipConfigurations[index].publicIpAddress, 'domainNameLabel') ? {
                    domainNameLabel: interface.ipConfigurations[index].publicIpAddress.domainNameLabel
                  } : null)
                  idleTimeoutInMinutes: (interface.ipConfigurations[index].publicIpAddress.?idleTimeoutInMinutes ?? null)
                  publicIPAddressVersion: (interface.ipConfigurations[index].publicIpAddress.?version ?? 'IPv4')
                  publicIPAllocationMethod: (interface.ipConfigurations[index].publicIpAddress.?allocationMethod ?? 'Static')
                }
                sku: (interface.ipConfigurations[index].publicIpAddress.?sku ?? { name: 'Standard' })
              } : null)
              subnet: { id: resourceId((interface.ipConfigurations[index].privateIpAddress.subnet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/virtualNetworks/subnets', interface.ipConfigurations[index].privateIpAddress.subnet.virtualNetworkName, interface.ipConfigurations[index].privateIpAddress.subnet.name) }
            }
          })
          networkSecurityGroup: (contains(interface, 'networkSecurityGroup') ? {
            id: resourceId((interface.networkSecurityGroup.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/networkSecurityGroups', interface.networkSecurityGroup.name)
          } : null)
          primary: (interface.?isPrimary ?? ((0 == index) && (0 == length(filter(properties.networkInterfaces, interface => contains(interface, 'isPrimary'))))))
        }
      }]
      networkInterfaces: [for (interface, index) in filter(properties.networkInterfaces, interface => contains(interface, 'name')): {
        id: networkInterfacesRef[index].id
        properties: {
          deleteOption: (interface.?deleteOption ?? 'Detach')
          primary: (interface.?isPrimary ?? ((0 == index) && (0 == length(filter(properties.networkInterfaces, interface => contains(interface, 'isPrimary'))))))
        }
      }]
    }
    osProfile: {
      adminPassword: administrator.password
      adminUsername: administrator.name
      allowExtensionOperations: true
      computerName: (properties.?operatingSystem.?computerName ?? name)
      linuxConfiguration: (isLinux ? {
        enableVMAgentPlatformUpdates: isAgentPlatformUpdateEnabled
        patchSettings: {
          assessmentMode: operatingSystemPatchSettings.assessmentMode
          patchMode: operatingSystemPatchSettings.patchMode
        }
        provisionVMAgent: isGuestAgentEnabled
      } : null)
      windowsConfiguration: (isWindows ? {
        enableAutomaticUpdates: ('manual' != toLower(operatingSystemPatchSettings.patchMode))
        enableVMAgentPlatformUpdates: isAgentPlatformUpdateEnabled
        patchSettings: {
          assessmentMode: operatingSystemPatchSettings.assessmentMode
          enableHotpatching: (properties.operatingSystem.?patchSettings.?isHotPatchingEnabled ?? isAgentPlatformUpdateEnabled)
          patchMode: operatingSystemPatchSettings.patchMode
        }
        provisionVMAgent: isGuestAgentEnabled
        timeZone: (properties.operatingSystem.?timeZone ?? null)
      } : null)
    }
    priority: (isSpotSettingsNotEmpty ? 'Spot' : null)
    proximityPlacementGroup: (isProximityPlacementGroupNotEmpty ? { id: proximityPlacementGroupRef.id } : null)
    securityProfile: {
      encryptionAtHost: (properties.?isEncryptionAtHostEnabled ?? null)
      securityType: (isSecureBootEnabled ? 'TrustedLaunch' : null)
      uefiSettings: (isSecureBootEnabled ? {
        secureBootEnabled: true
        vTpmEnabled: isVirtualTrustedPlatformModuleEnabled
      } : null)
    }
    storageProfile: {
      dataDisks: [for (disk, index) in (properties.?dataDisks ?? []): {
        caching: (disk.?cachingMode ?? 'None')
        createOption: (disk.?createOption ?? 'Empty')
        deleteOption: (disk.?deleteOption ?? 'Delete')
        diskSizeGB: disk.sizeInGigabytes
        lun: index
        managedDisk: {
          diskEncryptionSet: (isDiskEncryptionSetNotEmpty ? { id: diskEncryptionSetRef.id } : null)
          storageAccountType: (disk.?storageAccountType ?? 'Standard_LRS')
        }
        name: (disk.?name ?? '${name}-Disk-${padLeft((index + 1), 5, '0')}')
        writeAcceleratorEnabled: (disk.?isWriteAcceleratorEnabled ?? null)
      }]
      imageReference: (isComputeGalleryNotEmpty ? { id: computeGalleryImageRef.id } : (properties.?imageReference ?? null))
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
          diskEncryptionSet: (isDiskEncryptionSetNotEmpty ? { id: diskEncryptionSetRef.id } : null)
          storageAccountType: (properties.operatingSystem.?disk.?storageAccountType ?? 'Standard_LRS')
        }
        name: (properties.operatingSystem.?disk.?name ?? '${name}-Disk-00000')
        osType: properties.operatingSystem.type
        writeAcceleratorEnabled: (properties.operatingSystem.?disk.?isWriteAcceleratorEnabled ?? null)
      }
    }
    virtualMachineScaleSet: (isVirtualMachineScaleSetNotEmpty ? { id: virtualMachineScaleSet.id } : null)
  }
  tags: tags
  zones: (properties.?availabilityZones ?? null)
}
resource virtualMachineScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' existing = if (isVirtualMachineScaleSetNotEmpty) {
  name: properties.virtualMachineScaleSet.name
  scope: resourceGroup((properties.virtualMachineScaleSet.?subscriptionId ?? subscriptionId), (properties.virtualMachineScaleSet.?resourceGroupName ?? resourceGroupName))
}
