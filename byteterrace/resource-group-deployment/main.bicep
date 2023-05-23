type managedDiskStorageAccountType = ('Premium_LRS' | 'Premium_ZRS' | 'PremiumV2_LRS' | 'Standard_LRS' | 'StandardSSD_LRS' | 'StandardSSD_ZRS' | 'UltraSSD_LRS')
type parametersInfo = {
  virtualMachines: virtualMachine[]?
}
type resourceIdentity = {
  type: string
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
        backEndAddressPoolNames: string[]?
        name: string
        resourceGroupName: string?
      }[]?
      applicationSecurityGroups: resourceReference[]?
      isPrimary: bool?
      loadBalancers: {
        backEndAddressPoolNames: string[]?
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
  }[]?
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
  }?
  proximityPlacementGroup: resourceReference?
  roleAssignments: array?
  scripts: array?
  sku: resourceSku?
  spotSettings: {
    evictionPolicy: ('Deallocate' | 'Delete')
    maximumPrice: int?
  }?
  tags: object?
  virtualMachineScaleSet: resourceReference?
}

param location string = resourceGroup().location
param parameters parametersInfo = {}
param tags object = {}

var deployment = {
  location: location
  name: az.deployment().name
}

module virtualMachines '../../microsoft/compute/virtual-machines/main.bicep' = [for (machine, index) in (parameters.?virtualMachines ?? []): {
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
      operatingSystem: (machine.?operatingSystem ?? null)
      proximityPlacementGroup: (machine.?proximityPlacementGroup ?? null)
      roleAssignments: (machine.?roleAssignments ?? null)
      scripts: (machine.?scripts ?? null)
      sku: (machine.?sku ?? null)
      spotSettings: (machine.?spotSettings ?? null)
      virtualMachineScaleSet: (machine.?virtualMachineScaleSet ?? null)
    }
    tags: (machine.?tags ?? tags)
  }
}]
