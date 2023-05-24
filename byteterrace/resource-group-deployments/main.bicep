type applicationSecurityGroup = {
  location: string?
  name: string?
  tags: object?
}
type availabilitySet = {
  faultDomainCount: int
  location: string?
  name: string?
  proximityPlacementGroup: resourceReference?
  tags: object?
  updateDomainCount: int
}
type capacityReservationGroup = {
  availabilityZones: string[]?
  location: string?
  name: string?
  reservations: {
    availabilityZones: string[]?
    name: string?
    sku: resourceSku
    tags: object?
  }[]?
  tags: object?
}
type computeGallery = {
  description: string?
  location: string?
  name: string?
  tags: object?
}
type containerRegistry = {
  firewallRules: string[]?
  identity: resourceIdentity?
  isAllowTrustedMicrosoftServicesEnabled: bool?
  isAnonymousPullEnabled: bool?
  isContentTrustPolicyEnabled: bool?
  isDedicatedDataEndpointEnabled: bool?
  isExportPolicyEnabled: bool?
  isPublicNetworkAccessEnabled: bool?
  isQuarantinePolicyEnabled: bool?
  isZoneRedundancyEnabled: bool?
  location: string?
  name: string?
  roleAssignments: array?
  sku: resourceSku
  tags: object?
}
type diskEncryptionSet = {
  encryptionType: ('ConfidentialVmEncryptedWithCustomerKey' | 'EncryptionAtRestWithCustomerKey' | 'EncryptionAtRestWithPlatformAndCustomerKeys')
  identity: resourceIdentity
  keyName: string
  keyVault: resourceReference?
  location: string?
  name: string?
  tags: object?
}
type keyVault = {
  firewallRules: string[]
  isDiskEncryptionEnabled: bool?
  isPublicNetworkAccessEnabled: bool?
  isPurgeProtectionEnabled: bool?
  isTemplateDeploymentEnabled: bool?
  isVirtualMachineDeploymentEnabled: bool?
  location: string?
  name: string?
  roleAssignments: array?
  sku: resourceSku
  softDeleteRetentionInDays: int?
  tags: object?
  tenantId: string?
  virtualNetworkRules: virtualNetworkRule[]?
}
type managedDiskStorageAccountType = ('Premium_LRS' | 'Premium_ZRS' | 'PremiumV2_LRS' | 'Standard_LRS' | 'StandardSSD_LRS' | 'StandardSSD_ZRS' | 'UltraSSD_LRS')
type propertiesInfo = {
  applicationSecurityGroups: applicationSecurityGroup[]?
  availabilitySets: availabilitySet[]?
  capacityReservationGroups: capacityReservationGroup[]?
  computeGalleries: computeGallery[]?
  containerRegistries: containerRegistry[]?
  diskEncryptionSets: diskEncryptionSet[]?
  keyVaults: keyVault[]?
  proximityPlacementGroups: proximityPlacementGroup[]?
  userManagedIdentities: userManagedIdentity[]?
  virtualMachines: virtualMachine[]?
}
type proximityPlacementGroup = {
  location: string?
  name: string?
  tags: object?
}
type resourceIdentity = {
  type: string?
  userAssignedIdentities: resourceReference[]?
}
type resourceReference = {
  name: string
  resourceGroupName: string?
  subscriptionId: string?
}
type resourceSku = {
  capacity: int?
  name: string
  tier: string?
}
type subnetReference = {
  name: string
  resourceGroupName: string?
  subscriptionId: string?
  virtualNetworkName: string
}
type virtualMachine = {
  automaticShutdown: {
    dailyRecurrence: {
      time: string
    }?
    hourlyRecurrence: {
      minute: int
    }?
    isEnabled: bool?
    notificationSettings: {
      emailRecipients: string[]?
      webhookUrl: string?
    }?
    timeZone: string
    weeklyRecurrence: {
      time: string
      weekdays: string[]
    }?
  }?
  availabilitySet: resourceReference?
  availabilityZones: string[]?
  bootDiagnostics: {
    isEnabled: bool?
    storageAccount: resourceReference
  }?
  capacityReservationGroup: resourceReference?
  certificates: object?
  dataDisks: {
    cachingMode: ('None' | 'ReadOnly' | 'ReadWrite')?
    createOption: ('Attach' | 'Empty' | 'FromImage')?
    deleteOption: ('Delete' | 'Detach')?
    isWriteAcceleratorEnabled: bool?
    name: string?
    sizeInGigabytes: int
    storageAccountType: managedDiskStorageAccountType?
  }[]?
  diskEncryptionSet: resourceReference?
  identity: resourceIdentity?
  imageReference: {
    offer: string?
    publisher: string?
    sku: string?
    version: string?
  }?
  isEncryptionAtHostEnabled: bool?
  isGuestAgentEnabled: bool?
  isHibernationEnabled: bool?
  isSecureBootEnabled: bool?
  isUltraSsdEnabled: bool?
  isVirtualTrustedPlatformModuleEnabled: bool?
  licenseType: string?
  location: string?
  name: string?
  networkInterfaces: {
    deleteOption: ('Delete' | 'Detach')?
    dnsServers: string[]?
    dscpConfiguration: resourceReference?
    isAcceleratedNetworkingEnabled: bool?
    isFpgaNetworkingEnabled: bool?
    isIpForwardingEnabled: bool?
    isPrimary: bool?
    isTcpStateTrackingEnabled: bool?
    ipConfigurations: {
      applicationGateways: {
        backEndAddressPoolNames: string[]
        name: string
        resourceGroupName: string?
      }[]?
      applicationSecurityGroups: resourceReference[]?
      isPrimary: bool?
      loadBalancers: {
        backEndAddressPoolNames: string[]
        name: string
        resourceGroupName: string?
      }[]?
      name: string?
      privateIpAddress: {
        subnet: subnetReference
        version: ('IPv4' | 'IPv6')?
      }
      publicIpAddress: {
        allocationMethod: ('Dynamic' | 'Static')?
        domainNameLabel: string?
        idleTimeoutInMinutes: int?
        sku: resourceSku?
        version: ('IPv4' | 'IPv6')?
      }?
    }[]?
    name: string?
    networkSecurityGroup: resourceReference?
    resourceGroupName: string?
    subscriptionId: string?
  }[]
  operatingSystem: {
    administrator: {
      name: string?
      password: string?
    }?
    computerName: string?
    disk: {
      cachingMode: ('None' | 'ReadOnly' | 'ReadWrite')?
      createOption: ('Attach' | 'Empty' | 'FromImage')?
      deleteOption: ('Delete' | 'Detach')?
      ephemeralPlacement: ('CacheDisk' | 'ResourceDisk')?
      isWriteAcceleratorEnabled: bool?
      name: string?
      sizeInGigabytes: int?
      storageAccountType: managedDiskStorageAccountType?
    }?
    patchSettings: {
      assessmentMode: ('AutomaticByPlatform' | 'ImageDefault')?
      isHotPatchingEnabled: bool?
      patchMode: ('AutomaticByOS' | 'AutomaticByPlatform' | 'Manual')?
    }?
    timeZone: string?
    type: ('Linux' | 'Windows')
  }
  proximityPlacementGroup: resourceReference?
  roleAssignments: array?
  scripts: array?
  sku: resourceSku
  spotSettings: {
    evictionPolicy: ('Deallocate' | 'Delete')
    maximumPrice: int?
  }?
  tags: object?
  virtualMachineScaleSet: resourceReference?
}
type virtualNetworkRule = {
  name: string?
  subnet: subnetReference
}
type userManagedIdentity = {
  location: string?
  name: string?
  tags: object?
}

param location string = resourceGroup().location
param properties propertiesInfo = {}
param tags object = {}

var deployment = {
  location: location
  name: az.deployment().name
}

module availabilitySets 'br/bytrc:microsoft/compute/availability-sets:0.0.0' = [for (set, index) in (properties.?availabilitySets ?? []): {
  dependsOn: [ proximityPlacementGroups ]
  name: '${deployment.name}-as-${padLeft(index, 3, '0')}'
  params: {
    location: (set.?location ?? deployment.location)
    name: (set.?name ?? 'as${padLeft(index, 5, '0')}')
    properties: {
      faultDomainCount: set.faultDomainCount
      proximityPlacementGroup: (set.?proximityPlacementGroup ?? null)
      updateDomainCount: set.updateDomainCount
    }
    tags: (set.?tags ?? tags)
  }
}]
module applicationSecurityGroups 'br/bytrc:microsoft/network/application-security-groups:0.0.0' = [for (group, index) in (properties.?applicationSecurityGroups ?? []): {
  name: '${deployment.name}-asg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'asg${padLeft(index, 5, '0')}')
    tags: (group.?tags ?? tags)
  }
}]
module capacityReservationGroups 'br/bytrc:microsoft/compute/capacity-reservation-groups:0.0.0' = [for (group, index) in (properties.?capacityReservationGroups ?? []): {
  name: '${deployment.name}-crg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'crg${padLeft(index, 5, '0')}')
    properties: {
      availabilityZones: (group.?availabilityZones ?? null)
      reservations: (group.?reservations ?? null)
    }
    tags: (group.?tags ?? tags)
  }
}]
module computeGalleries 'br/bytrc:microsoft/compute/galleries:0.0.0' = [for (gallery, index) in (properties.?computeGalleries ?? []): {
  name: '${deployment.name}-cg-${padLeft(index, 3, '0')}'
  params: {
    location: (gallery.?location ?? deployment.location)
    name: (gallery.?name ?? 'cg${padLeft(index, 5, '0')}')
    properties: {
      description: (gallery.?description ?? null)
    }
    tags: (gallery.?tags ?? tags)
  }
}]
module containerRegistries 'br/bytrc:microsoft/container-registry/registries:0.0.0' = [for (registry, index) in (properties.?containerRegistries ?? []): {
  dependsOn: [
    keyVaults
    userManagedIdentities
  ]
  name: '${deployment.name}-cr-${padLeft(index, 3, '0')}'
  params: {
    location: (registry.?location ?? deployment.location)
    name: (registry.?name ?? 'cr${padLeft(index, 5, '0')}')
    properties: {
      firewallRules: (registry.?firewallRules ?? null)
      identity: (registry.?identity ?? null)
      isAllowTrustedMicrosoftServicesEnabled: (registry.?isAllowTrustedMicrosoftServicesEnabled ?? null)
      isAnonymousPullEnabled: (registry.?isAnonymousPullEnabled ?? null)
      isContentTrustPolicyEnabled: (registry.?isContentTrustPolicyEnabled ?? null)
      isDedicatedDataEndpointEnabled: (registry.?isDedicatedDataEndpointEnabled ?? null)
      isExportPolicyEnabled: (registry.?isExportPolicyEnabled ?? null)
      isPublicNetworkAccessEnabled: (registry.?isPublicNetworkAccessEnabled ?? null)
      isQuarantinePolicyEnabled: (registry.?isQuarantinePolicyEnabled ?? null)
      isZoneRedundancyEnabled: (registry.?isZoneRedundancyEnabled ?? null)
      roleAssignments: (registry.?roleAssignments ?? null)
      sku: registry.sku
    }
    tags: (registry.?tags ?? tags)
  }
}]
module diskEncryptionSets 'br/bytrc:microsoft/compute/disk-encryption-sets:0.0.0' = [for (set, index) in (properties.?diskEncryptionSets ?? []): {
  dependsOn: [
    keyVaults
    userManagedIdentities
  ]
  name: '${deployment.name}-des-${padLeft(index, 3, '0')}'
  params: {
    location: (set.?location ?? deployment.location)
    name: (set.?name ?? 'des${padLeft(index, 5, '0')}')
    properties: {
      encryptionType: set.encryptionType
      identity: (set.?identity ?? null)
      keyName: set.keyName
      keyVault: set.keyVault
    }
    tags: (set.?tags ?? tags)
  }
}]
module keyVaults 'br/bytrc:microsoft/key-vault/vaults:0.0.0' = [for (vault, index) in (properties.?keyVaults ?? []): {
  name: '${deployment.name}-kv-${padLeft(index, 3, '0')}'
  params: {
    location: (vault.?location ?? deployment.location)
    name: (vault.?name ?? 'kv${padLeft(index, 5, '0')}')
    properties: {
      firewallRules: (vault.?firewallRules ?? null)
      isDiskEncryptionEnabled: (vault.?isDiskEncryptionEnabled ?? null)
      isPublicNetworkAccessEnabled: (vault.?isPublicNetworkAccessEnabled ?? null)
      isPurgeProtectionEnabled: (vault.?isPurgeProtectionEnabled ?? null)
      isTemplateDeploymentEnabled: (vault.?isTemplateDeploymentEnabled ?? null)
      isVirtualMachineDeploymentEnabled: (vault.?isVirtualMachineDeploymentEnabled ?? null)
      roleAssignments: (vault.?roleAssignments ?? null)
      sku: vault.sku
      softDeleteRetentionInDays: (vault.?softDeleteRetentionInDays ?? null)
      tenantId: (vault.?tenantId ?? null)
      virtualNetworkRules: (vault.?virtualNetworkRules ?? null)
    }
    tags: (vault.?tags ?? tags)
  }
}]
module proximityPlacementGroups 'br/bytrc:microsoft/compute/proximity-placement-groups:0.0.0' = [for (group, index) in (properties.?proximityPlacementGroups ?? []): {
  name: '${deployment.name}-ppg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'ppg${padLeft(index, 5, '0')}')
    tags: (group.?tags ?? tags)
  }
}]
module userManagedIdentities 'br/bytrc:microsoft/managed-identity/user-assigned-identities:0.0.0' = [for (identity, index) in (properties.?userManagedIdentities ?? []): {
  name: '${deployment.name}-umi-${padLeft(index, 3, '0')}'
  params: {
    location: (identity.?location ?? deployment.location)
    name: (identity.?name ?? 'umi${padLeft(index, 5, '0')}')
    tags: (identity.?tags ?? tags)
  }
}]
module virtualMachines 'br/bytrc:microsoft/compute/virtual-machines:0.0.0' = [for (machine, index) in (properties.?virtualMachines ?? []): {
  dependsOn: [
    applicationSecurityGroups
    availabilitySets
    capacityReservationGroups
    computeGalleries
    diskEncryptionSets
    keyVaults
    proximityPlacementGroups
    userManagedIdentities
  ]
  name: '${deployment.name}-vm-${padLeft(index, 3, '0')}'
  params: {
    location: (machine.?location ?? deployment.location)
    name: (machine.?name ?? 'vm${padLeft(index, 5, '0')}')
    properties: {
      automaticShutdown: (machine.?automaticShutdown ?? null)
      availabilitySet: (machine.?availabilitySet ?? null)
      bootDiagnostics: (machine.?bootDiagnostics ?? null)
      capacityReservationGroup: (machine.?capacityReservationGroup ?? null)
      certificates: (machine.?certificates ?? null)
      dataDisks: (machine.?dataDisks ?? null)
      diskEncryptionSet: (machine.?diskEncryptionSet ?? null)
      identity: (machine.?identity ?? null)
      imageReference: (machine.?imageReference ?? null)
      isEncryptionAtHostEnabled: (machine.?isEncryptionAtHostEnabled ?? null)
      isGuestAgentEnabled: (machine.?isGuestAgentEnabled ?? null)
      isHibernationEnabled: (machine.?isHibernationEnabled ?? null)
      isSecureBootEnabled: (machine.?isSecureBootEnabled ?? null)
      isUltraSsdEnabled: (machine.?isUltraSsdEnabled ?? null)
      isVirtualTrustedPlatformModuleEnabled: (machine.?isVirtualTrustedPlatformModuleEnabled ?? null)
      licenseType: (machine.?licenseType ?? null)
      networkInterfaces: machine.networkInterfaces
      operatingSystem: machine.operatingSystem
      proximityPlacementGroup: (machine.?proximityPlacementGroup ?? null)
      roleAssignments: (machine.?roleAssignments ?? null)
      scripts: (machine.?scripts ?? null)
      sku: machine.sku
      spotSettings: (machine.?spotSettings ?? null)
      virtualMachineScaleSet: (machine.?virtualMachineScaleSet ?? null)
    }
    tags: (machine.?tags ?? tags)
  }
}]
