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
var dataDisks = sort(items(properties.?dataDisks ?? {}), (x, y) => (x.key < y.key))
var identity = (properties.?identity ?? {})
var isAgentPlatformUpdateEnabled = ('automaticbyplatform' == toLower(operatingSystemPatchSettings.patchMode))
var isBootDiagnosticsStorageAccountNotEmpty = !empty(properties.?bootDiagnostics.?storageAccount ?? {})
var isCapacityReservationGroupNotEmpty = !empty(properties.?capacityReservationGroup ?? {})
var isComputeGalleryNotEmpty = !empty(properties.?imageReference.?gallery ?? {})
var isDiskEncryptionSetNotEmpty = !empty(properties.?diskEncryptionSet ?? {})
var isGuestAgentEnabled = (properties.?isGuestAgentEnabled ?? true)
var isIdentityNotEmpty = !empty(identity)
var isLinux = ('linux' == toLower(properties.operatingSystem.type))
var isProximityPlacementGroupNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var isSecureBootEnabled = (properties.?isSecureBootEnabled ?? true)
var isSpotSettingsNotEmpty = !empty(properties.?spotSettings ?? {})
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
var isVirtualTrustedPlatformModuleEnabled = (properties.?isVirtualTrustedPlatformModuleEnabled ?? true)
var isWindows = ('windows' == toLower(properties.operatingSystem.type))
var networkInterfaces = sort(items(properties.networkInterfaces), (x, y) => (x.key < y.key))
var operatingSystemPatchSettings = {
  assessmentMode: (properties.operatingSystem.?patchSettings.?assessmentMode ?? 'AutomaticByPlatform')
  patchMode: (properties.operatingSystem.?patchSettings.?patchMode ?? 'AutomaticByPlatform')
}
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = sort(map(range(0, length(identity.?userAssignedIdentities ?? [])), index => {
  id: resourceId((identity.userAssignedIdentities[index].?subscriptionId ?? subscriptionId), (identity.userAssignedIdentities[index].?resourceGroupName ?? resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', identity.userAssignedIdentities[index].name)
  index: index
  value: identity.userAssignedIdentities[index]
}), (x, y) => (x.index < y.index))

resource bootDiagnosticsStorageAccountRef 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (isBootDiagnosticsStorageAccountNotEmpty) {
  name: properties.bootDiagnostics.storageAccount.name
  scope: resourceGroup((properties.bootDiagnostics.?subscriptionId ?? subscriptionId), (properties.bootDiagnostics.?resourceGroupName ?? resourceGroupName))
}
resource capacityReservationGroupRef 'Microsoft.Compute/capacityReservationGroups@2023-03-01' existing = if (isCapacityReservationGroupNotEmpty) {
  name: properties.capacityReservationGroup.name
  scope: resourceGroup((properties.capacityReservationGroup.?subscriptionId ?? subscriptionId), (properties.capacityReservationGroup.?resourceGroupName ?? resourceGroupName))
}
resource computeGalleryImageRef 'Microsoft.Compute/galleries/images/versions@2022-03-03' existing = if (isComputeGalleryNotEmpty) {
  name: '${properties.imageReference.gallery.name}/${properties.imageReference.name}/${(properties.imageReference.?version ?? 'latest')}'
  scope: resourceGroup((properties.imageReference.gallery.?subscriptionId ?? subscriptionId), (properties.imageReference.gallery.?resourceGroupName ?? resourceGroupName))
}
resource diskEncryptionSetRef 'Microsoft.Compute/diskEncryptionSets@2022-07-02' existing = if (isDiskEncryptionSetNotEmpty) {
  name: properties.diskEncryptionSet.name
  scope: resourceGroup((properties.diskEncryptionSet.?subscriptionId ?? subscriptionId), (properties.diskEncryptionSet.?resourceGroupName ?? resourceGroupName))
}
resource proximityPlacementGroupRef 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' existing = if (isProximityPlacementGroupNotEmpty) {
  name: properties.proximityPlacementGroup.name
  scope: resourceGroup((properties.proximityPlacementGroup.?subscriptionId ?? subscriptionId), (properties.proximityPlacementGroup.?resourceGroupName ?? resourceGroupName))
}
resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
}): {
  name: sys.guid(virtualMachineScaleSet.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
  }
  scope: virtualMachineScaleSet
}]
resource virtualMachineScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' = {
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
    orchestrationMode: 'Uniform'
    proximityPlacementGroup: (isProximityPlacementGroupNotEmpty ? { id: proximityPlacementGroupRef.id } : null)
    virtualMachineProfile: {
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
      extensionProfile: {
        extensionsTimeBudget: 'PT47M'
      }
      licenseType: (properties.?licenseType ?? null)
      networkProfile: {
        networkApiVersion: '2020-11-01'
        networkInterfaceConfigurations: [for (interface, index) in networkInterfaces: {
          name: interface.key
          properties: {
            deleteOption: 'Delete'
            disableTcpStateTracking: !(interface.value.?isTcpStateTrackingEnabled ?? true)
            dnsSettings: {
              dnsServers: (interface.value.?dnsServers ?? [])
            }
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
                  name: configuration.value.publicIpAddress.name
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
      }
      priority: (isSpotSettingsNotEmpty ? 'Spot' : null)
      osProfile: {
        adminPassword: administrator.password
        adminUsername: administrator.name
        allowExtensionOperations: true
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
    }
  }
  sku: properties.sku
  tags: tags
  zones: (properties.?availabilityZones ?? [])
}
