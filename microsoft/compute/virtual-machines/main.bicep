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
var certificates = sort(items(properties.?certificates ?? {}), (x, y) => (x.key < y.key))
var dataDisks = sort(items(properties.?dataDisks ?? {}), (x, y) => (x.key < y.key))
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
var isLinux = ('linux' == toLower(properties.operatingSystem.type))
var isProximityPlacementGroupNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var isSecureBootEnabled = (properties.?isSecureBootEnabled ?? true)
var isSpotSettingsNotEmpty = !empty(properties.?spotSettings ?? {})
var isSystemAssignedIdentityEnabled = contains((identity.?type ?? ''), 'systemassigned')
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var isVirtualMachineScaleSetNotEmpty = !empty(properties.?virtualMachineScaleSet ?? {})
var isVirtualTrustedPlatformModuleEnabled = (properties.?isVirtualTrustedPlatformModuleEnabled ?? true)
var isWindows = ('windows' == toLower(properties.operatingSystem.type))
var networkInterfaces = sort(items(properties.networkInterfaces), (x, y) => (x.key < y.key))
var operatingSystemPatchSettings = {
  assessmentMode: (properties.operatingSystem.?patchSettings.?assessmentMode ?? 'AutomaticByPlatform')
  patchMode: (properties.operatingSystem.?patchSettings.?patchMode ?? 'AutomaticByPlatform')
}
var resourceGroupName = resourceGroup().name
var roleAssignmentsTransform = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  resource: (empty(assignment.resource) ? null : {
    apiVersion: assignment.resource.apiVersion
    id: '/subscriptions/${(assignment.resource.?subscriptionId ?? subscriptionId)}/resourceGroups/${(assignment.resource.?resourceGroupName ?? resourceGroupName)}/providers/${assignment.resource.type}/${assignment.resource.path}'
    type: assignment.resource.type
  })
  roleDefinitionId: assignment.roleDefinitionId
})
var scripts = sort(map(items(properties.?scripts ?? {}), script => {
  blobPath: (script.value.?blobPath ?? '')
  containerName: (script.value.?containerName ?? null)
  errorBlobPath: (script.value.?errorBlobPath ?? '')
  errorBlobUri: (script.value.?errorBlobUri ?? null)
  key: script.key
  outputBlobPath: (script.value.?outputBlobPath ?? '')
  outputBlobUri: (script.value.?outputBlobUri ?? null)
  parameters: map(items(script.value.?parameters ?? {}), parameter => {
    name: parameter.key
    value: parameter.value
  })
  storageAccount: (script.value.?storageAccount ?? {})
  tags: (script.value.?tags ?? tags)
  timeoutInSeconds: (script.value.?timeoutInSeconds ?? null)
  uri: (script.value.?uri ?? null)
  value: (script.value.?value ?? null)
}), (x, y) => (x.key < y.key))
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = items(identity.?userAssignedIdentities ?? {})
var userAssignedIdentitiesWithResourceId = [for (identity, index) in userAssignedIdentities: {
  index: index
  isPrimary: (identity.value.?isPrimary ?? (1 == length(userAssignedIdentities)))
  resourceId: userAssignedIdentitiesRef[index].id
}]

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
        msiClientId: (isUserAssignedIdentitiesNotEmpty ? userAssignedIdentitiesRef[any(first(filter(userAssignedIdentitiesWithResourceId, identity => identity.isPrimary))).index].properties.clientId: (isSystemAssignedIdentityEnabled ? systemAssignedIdentityRef.properties.clientId : null))
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
resource networkInterfacesRef 'Microsoft.Network/networkInterfaces@2022-11-01' existing = [for interface in networkInterfaces: {
  name: interface.key
  scope: resourceGroup((interface.value.?subscriptionId ?? subscriptionId), (interface.value.?resourceGroupName ?? resourceGroupName))
}]
resource proximityPlacementGroupRef 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' existing = if (isProximityPlacementGroupNotEmpty) {
  name: properties.proximityPlacementGroup.name
  scope: resourceGroup((properties.proximityPlacementGroup.?subscriptionId ?? subscriptionId), (properties.proximityPlacementGroup.?resourceGroupName ?? resourceGroupName))
}
@batchSize(1)
resource runCommands 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [for (script, index) in scripts: {
  dependsOn: [
    guestAttestation
    keyVaultIntegration
  ]
  location: location
  name: script.key
  parent: virtualMachine
  properties: {
    asyncExecution: false
    errorBlobUri: (empty(script.errorBlobPath) ? script.errorBlobUri : format('{0}{1}/{2}?{3}', scriptStorageAccountsRef[index].properties.primaryEndpoints.blob, script.containerName, script.errorBlobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
      canonicalizedResource: '/blob/${script.storageAccount.name}/${script.containerName}/${script.errorBlobPath}'
      signedExpiry: dateTimeAdd(utcNow, 'PT3H')
      signedPermission: 'rwacu'
      signedProtocol: 'https'
      signedResourceTypes: 'o'
      signedServices: 'b'
    }).accountSasToken))
    outputBlobUri: (empty(script.outputBlobPath) ? script.outputBlobUri : format('{0}{1}/{2}?{3}', scriptStorageAccountsRef[index].properties.primaryEndpoints.blob, script.containerName, script.outputBlobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
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
      scriptUri: (empty(script.blobPath) ? script.uri : format('{0}{1}/{2}?{3}', scriptStorageAccountsRef[index].properties.primaryEndpoints.blob, script.containerName, script.blobPath, listAccountSAS(script.storageAccount.id, '2022-09-01', {
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
resource scriptStorageAccountsRef 'Microsoft.Storage/storageAccounts@2022-09-01' existing = [for script in scripts: if (!empty(script.storageAccount)) {
  name: script.storageAccount.name
  scope: resourceGroup((script.storageAccount.?subscriptionId ?? subscriptionId), (script.storageAccount.?resourceGroupName ?? resourceGroupName))
}]
resource systemAssignedIdentityRef 'Microsoft.ManagedIdentity/identities@2023-01-31' existing = if (isSystemAssignedIdentityEnabled) {
  name: 'default'
  scope: virtualMachine
}
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.key
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  identity: {
    type: (identity.?type ?? (isUserAssignedIdentitiesNotEmpty ? 'UserAssigned' : 'None'))
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty? toObject(userAssignedIdentitiesWithResourceId, identity => identity.resourceId, identity => {}) : null)
  }
  location: location
  name: name
  properties: {
    additionalCapabilities: {
      hibernationEnabled: (properties.?isHibernationEnabled ?? null)
      ultraSSDEnabled: (properties.?isUltraSsdEnabled ?? null)
    }
    availabilitySet: (isAvailabilitySetNotEmpty ? { id: availabilitySetRef.id } : null)
    billingProfile: (isSpotSettingsNotEmpty ? {
      maxPrice: (properties.spotSettings.?maximumPrice ?? -1)
    } : null)
    capacityReservation: (isCapacityReservationGroupNotEmpty ? { capacityReservationGroup: { id: capacityReservationGroupRef.id } } : null)
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: (properties.?bootDiagnostics.?isEnabled ?? isBootDiagnosticsStorageAccountNotEmpty)
        storageUri: (isBootDiagnosticsStorageAccountNotEmpty ? bootDiagnosticsStorageAccountRef.properties.primaryEndpoints.blob : null)
      }
    }
    evictionPolicy: (isSpotSettingsNotEmpty ? properties.spotSettings.evictionPolicy : null)
    extensionsTimeBudget: 'PT47M'
    hardwareProfile: {
      vmSize: properties.sku.name
    }
    licenseType: (properties.?licenseType ?? null)
    networkProfile: {
      networkApiVersion: ((0 != length(filter(networkInterfaces, interface => !contains(interface.value, 'isExisting')))) ? '2020-11-01' : null)
      networkInterfaceConfigurations: [for (interface, index) in filter(networkInterfaces, interface => !contains(interface.value, 'isExisting')): {
        name: interface.key
        properties: {
          deleteOption: 'Delete'
          disableTcpStateTracking: !(interface.value.?isTcpStateTrackingEnabled ?? true)
          dnsSettings: {
            dnsServers: (interface.value.?dnsServers ?? [])
          }
          dscpConfiguration: (contains(interface, 'dscpConfiguration') ? {
            id: resourceId((interface.value.dscpConfiguration.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/dscpConfigurations', interface.value.dscpConfiguration.name)
          } : null)
          enableAcceleratedNetworking: (interface.value.?isAcceleratedNetworkingEnabled ?? true)
          enableFpga: (interface.value.?isFpgaNetworkingEnabled ?? null)
          enableIPForwarding: (interface.value.?isIpForwardingEnabled ?? false)
          ipConfigurations: map(items(interface.value.ipConfigurations), configuration => {
            name: configuration.key
            properties: {
              applicationGatewayBackendAddressPools: flatten(map(items(configuration.value.?applicationGateways ?? {}), gateway => map(gateway.value.backEndAddressPoolNames, name => {
                id: resourceId((gateway.value.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationGateways/backendAddressPools', gateway.key, name)
              })))
              applicationSecurityGroups: map(items(configuration.value.?applicationSecurityGroups ?? {}), group => {
                id: resourceId((group.value.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/applicationSecurityGroups', group.key)
              })
              loadBalancerBackendAddressPools: flatten(map(items(configuration.value.?loadBalancers ?? {}), loadBalancer => map(loadBalancer.value.backEndAddressPoolNames, name => {
                id: resourceId((loadBalancer.value.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/loadBalancers/backendAddressPools', loadBalancer.key, name)
              })))
              primary: (configuration.value.?isPrimary ?? (1 == length(interface.value.ipConfigurations)))
              privateIPAddressVersion: (configuration.value.privateIpAddress.?version ?? 'IPv4')
              publicIPAddressConfiguration: (contains(configuration.value, 'publicIpAddress') ? {
                name: 'default'
                properties: {
                  deleteOption: 'Delete'
                  dnsSettings: (contains(configuration.value.publicIpAddress, 'domainNameLabel') ? {
                    domainNameLabel: configuration.value.publicIpAddress.domainNameLabel
                  } : null)
                  idleTimeoutInMinutes: (configuration.value.publicIpAddress.?idleTimeoutInMinutes ?? null)
                  publicIPAddressVersion: (configuration.value.publicIpAddress.?version ?? 'IPv4')
                  publicIPAllocationMethod: (configuration.value.publicIpAddress.?allocationMethod ?? 'Static')
                }
                sku: (configuration.value.publicIpAddress.?sku ?? { name: 'Standard' })
              } : null)
              subnet: { id: resourceId((configuration.value.privateIpAddress.subnet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/virtualNetworks/subnets', configuration.value.privateIpAddress.subnet.virtualNetworkName, configuration.value.privateIpAddress.subnet.name) }
            }
          })
          networkSecurityGroup: (contains(interface, 'networkSecurityGroup') ? {
            id: resourceId((interface.value.networkSecurityGroup.?resourceGroupName ?? resourceGroupName), 'Microsoft.Network/networkSecurityGroups', interface.value.networkSecurityGroup.name)
          } : null)
          primary: (interface.value.?isPrimary ?? (1 == length(networkInterfaces)))
        }
      }]
      networkInterfaces: [for (interface, index) in filter(networkInterfaces, interface => contains(interface.value, 'isExisting')): {
        id: networkInterfacesRef[index].id
        properties: {
          deleteOption: (interface.value.?deleteOption ?? 'Detach')
          primary: (interface.value.?isPrimary ?? (1 == length(networkInterfaces)))
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
      dataDisks: [for (disk, index) in dataDisks: {
        caching: (disk.value.?cachingMode ?? 'None')
        createOption: (disk.value.?createOption ?? 'Empty')
        deleteOption: (disk.value.?deleteOption ?? 'Delete')
        diskSizeGB: disk.value.sizeInGigabytes
        lun: index
        managedDisk: {
          diskEncryptionSet: (isDiskEncryptionSetNotEmpty ? { id: diskEncryptionSetRef.id } : null)
          storageAccountType: (disk.value.?storageAccountType ?? 'Standard_LRS')
        }
        name: disk.key
        writeAcceleratorEnabled: (disk.value.?isWriteAcceleratorEnabled ?? null)
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
    virtualMachineScaleSet: (isVirtualMachineScaleSetNotEmpty ? { id: virtualMachineScaleSetRef.id } : null)
  }
  tags: tags
  zones: (properties.?availabilityZones ?? null)
}
resource virtualMachineRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(virtualMachine.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: virtualMachine
}]
resource virtualMachineScaleSetRef 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' existing = if (isVirtualMachineScaleSetNotEmpty) {
  name: properties.virtualMachineScaleSet.name
  scope: resourceGroup((properties.virtualMachineScaleSet.?subscriptionId ?? subscriptionId), (properties.virtualMachineScaleSet.?resourceGroupName ?? resourceGroupName))
}
