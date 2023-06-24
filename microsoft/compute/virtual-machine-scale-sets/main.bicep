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
var subscriptionId = subscription().subscriptionId
var userAssignedIdentities = items(identity.?userAssignedIdentities ?? {})
var userAssignedIdentitiesWithResourceId = [for (identity, index) in userAssignedIdentities: {
  index: index
  isPrimary: (identity.value.?isPrimary ?? (1 == length(userAssignedIdentities)))
  resourceId: userAssignedIdentitiesRef[index].id
}]

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
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.key
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
resource virtualMachineScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' = {
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
    orchestrationMode: 'Uniform'
    overprovision: (properties.?isOverprovisioningEnabled ?? null)
    proximityPlacementGroup: (isProximityPlacementGroupNotEmpty ? { id: proximityPlacementGroupRef.id } : null)
    upgradePolicy: {
      mode: 'Manual'
    }
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
        networkInterfaceConfigurations: [for (interface, index) in networkInterfaces: {
          name: interface.key
          properties: {
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
                  name: 'default'
                  properties: {
                    dnsSettings: (contains(configuration.value.publicIpAddress, 'domainNameLabel') ? {
                      domainNameLabel: configuration.value.publicIpAddress.domainNameLabel
                    } : null)
                    idleTimeoutInMinutes: (configuration.value.publicIpAddress.?idleTimeoutInMinutes ?? null)
                    publicIPAddressVersion: (configuration.value.publicIpAddress.?version ?? 'IPv4')
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
        computerNamePrefix: (properties.operatingSystem.?computerNamePrefix ?? toUpper(take(uniqueString(subscriptionId, resourceGroupName, name), 9)))
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
          diffDiskSettings: (contains((properties.operatingSystem.?disk ?? {}), 'ephemeralPlacement') ? {
            option: 'Local'
            placement: properties.operatingSystem.disk.ephemeralPlacement
          } : null)
          diskSizeGB: (properties.operatingSystem.?disk.?sizeInGigabytes ?? null)
          managedDisk: {
            diskEncryptionSet: (isDiskEncryptionSetNotEmpty ? { id: diskEncryptionSetRef.id } : null)
            storageAccountType: (properties.operatingSystem.?disk.?storageAccountType ?? 'Standard_LRS')
          }
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
resource virtualMachineScaleSetRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(virtualMachineScaleSet.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: virtualMachineScaleSet
}]
