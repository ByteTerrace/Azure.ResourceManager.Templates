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
  imageDefinitions: {
    architecture: ('Arm64' | 'x64')?
    description: string?
    generation: ('V1' | 'V2')?
    identifier: {
      offer: string
      publisher: string
      sku: string
    }
    isAcceleratedNetworkingSupported: bool?
    isHibernateSupported: bool?
    name: string
    operatingSystem: {
      state: ('Generalized' | 'Specialized')
      type: ('Linux' | 'Windows')
    }
    securityType: ('ConfidentialVM' | 'ConfidentialVmSupported' | 'Standard' | 'TrustedLaunch' | 'TrustedLaunchSupported')?
    tags: object?
  }[]?
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
type dnsResolver = {
  inboundEndpoints: {
    name: string?
    privateIpAddress: {
      subnet: {
        name: string
      }
      value: string?
    }
    tags: object?
  }[]?
  location: string?
  name: string?
  outboundEndpoints: {
    name: string?
    subnet: {
      name: string
    }
    tags: object?
  }[]?
  tags: object?
  virtualNetwork: resourceReference?
}
type keyVault = {
  firewallRules: string[]?
  isAllowTrustedMicrosoftServicesEnabled: bool?
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
type networkInterface = {
  dnsServers: string[]?
  ipConfigurations: {
    isPrimary: bool?
    name: string?
    privateIpAddress: {
      subnet: subnetReference
      value: string?
      version: ('IPv4' | 'IPv6')?
    }
    publicIpAddress: resourceReference?
  }[]
  isAcceleratedNetworkingEnabled: bool?
  isIpForwardingEnabled: bool?
  isTcpStateTrackingEnabled: bool?
  location: string?
  name: string?
  networkSecurityGroup: resourceReference?
  publicIpAddress: resourceReference?
  tags: object?
}
type networkSecurityGroup = {
  location: string?
  name: string?
  securityRules: {
    access: ('Allow' | 'Deny')
    description: string?
    destination: {
      addressPrefixes: string[]
      applicationSecurityGroups: resourceReference[]?
      ports: string[]
    }
    direction: ('Inbound' | 'Outbound')
    name: string
    protocol: ('*' | 'Ah' | 'Esp' | 'Icmp' | 'Tcp' | 'Udp')
    source: {
      addressPrefixes: string[]
      applicationSecurityGroups: resourceReference[]?
      ports: string[]
    }
  }[]?
  tags: object?
}
type propertiesInfo = {
  applicationSecurityGroups: applicationSecurityGroup[]?
  availabilitySets: availabilitySet[]?
  capacityReservationGroups: capacityReservationGroup[]?
  computeGalleries: computeGallery[]?
  containerRegistries: containerRegistry[]?
  diskEncryptionSets: diskEncryptionSet[]?
  dnsResolvers: dnsResolver[]?
  keyVaults: keyVault[]?
  networkInterfaces: networkInterface[]?
  networkSecurityGroups: networkSecurityGroup[]?
  proximityPlacementGroups: proximityPlacementGroup[]?
  publicIpAddresses: publicIpAddress[]?
  publicIpPrefixes: publicIpPrefix[]?
  routeTables: routeTable[]?
  userManagedIdentities: userManagedIdentity[]?
  virtualMachines: virtualMachine[]?
  virtualNetworks: virtualNetwork[]?
}
type proximityPlacementGroup = {
  location: string?
  name: string?
  tags: object?
}
type publicIpAddress = {
  allocationMethod: ('Dynamic' | 'Static')?
  deleteOption: ('Delete' | 'Detach')?
  idleTimeoutInMinutes: int?
  location: string?
  name: string?
  prefix: resourceReference?
  sku: resourceSku
  tags: object?
  version: ('IPv4' | 'IPV6')?
}
type publicIpPrefix = {
  customPrefix: resourceReference?
  length: int
  location: string?
  name: string?
  natGateway: resourceReference?
  sku: resourceSku
  tags: object?
  version: ('IPv4' | 'IPV6')?
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
type routeTable = {
  location: string?
  name: string?
  routes: {
    addressPrefix: string
    name: string
    nextHopIpAddress: string?
  }[]?
  tags: object?
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
    gallery: resourceReference?
    name: string?
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
  scripts: {
    blobPath: string?
    containerName: string?
    errorBlobPath: string?
    errorBlobUri: string?
    name: string?
    outputBlobPath: string?
    outputBlobUri: string?
    parameters: object?
    storageAccount: resourceReference?
    tags: object?
    timeoutInSeconds: int?
    uri: string?
    value: string?
  }[]?
  sku: resourceSku
  spotSettings: {
    evictionPolicy: ('Deallocate' | 'Delete')
    maximumPrice: int?
  }?
  tags: object?
  virtualMachineScaleSet: resourceReference?
}
type virtualNetwork = {
  addressPrefixes: string[]
  ddosProtectionPlan: resourceReference?
  dnsServers: string[]?
  location: string?
  name: string?
  subnets: {
    addressPrefixes: string[]
    delegations: string[]?
    name: string
    natGateway: resourceReference?
    networkSecurityGroup: resourceReference?
    privateEndpointNetworkPolicies: {
      isNetworkSecurityGroupEnabled: bool?
      isRouteTableEnabled: bool?
    }?
    privateLinkServiceNetworkPolicies: {
      isEnabled: bool?
    }?
    routeTable: resourceReference?
    serviceEndpoints: {
      locations: string[]?
      name: string
    }[]?
  }[]?
  tags: object?
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

param exclude array = []
param include array = []
param location string = resourceGroup().location
param properties propertiesInfo = {}
param tags object = {}

var deployment = {
  location: location
  name: az.deployment().name
}

module applicationSecurityGroups 'br/bytrc:microsoft/network/application-security-groups:0.0.0' = [for (group, index) in (properties.?applicationSecurityGroups ?? []): if (!contains(exclude, 'applicationSecurityGroups') && (empty(include) || contains(include, 'applicationSecurityGroups'))) {
  name: '${deployment.name}-asg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'asg${padLeft(index, 5, '0')}')
    tags: (group.?tags ?? tags)
  }
}]
module availabilitySets 'br/bytrc:microsoft/compute/availability-sets:0.0.0' = [for (set, index) in (properties.?availabilitySets ?? []): if (!contains(exclude, 'availabilitySets') && (empty(include) || contains(include, 'availabilitySets'))) {
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
module capacityReservationGroups 'br/bytrc:microsoft/compute/capacity-reservation-groups:0.0.0' = [for (group, index) in (properties.?capacityReservationGroups ?? []): if (!contains(exclude, 'capacityReservationGroups') && (empty(include) || contains(include, 'capacityReservationGroups'))) {
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
module computeGalleries 'br/bytrc:microsoft/compute/galleries:0.0.0' = [for (gallery, index) in (properties.?computeGalleries ?? []): if (!contains(exclude, 'computeGalleries') && (empty(include) || contains(include, 'computeGalleries'))) {
  name: '${deployment.name}-cg-${padLeft(index, 3, '0')}'
  params: {
    location: (gallery.?location ?? deployment.location)
    name: (gallery.?name ?? 'cg${padLeft(index, 5, '0')}')
    properties: {
      description: (gallery.?description ?? null)
      imageDefinitions: (gallery.?imageDefinitions ?? null)
    }
    tags: (gallery.?tags ?? tags)
  }
}]
module containerRegistries 'br/bytrc:microsoft/container-registry/registries:0.0.0' = [for (registry, index) in (properties.?containerRegistries ?? []): if (!contains(exclude, 'containerRegistries') && (empty(include) || contains(include, 'containerRegistries'))) {
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
module diskEncryptionSets 'br/bytrc:microsoft/compute/disk-encryption-sets:0.0.0' = [for (set, index) in (properties.?diskEncryptionSets ?? []): if (!contains(exclude, 'diskEncryptionSets') && (empty(include) || contains(include, 'diskEncryptionSets'))) {
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
module dnsResolvers 'br/bytrc:microsoft/network/dns-resolvers:0.0.0' = [for (resolver, index) in (properties.?dnsResolvers ?? []): if (!contains(exclude, 'dnsResolvers') && (empty(include) || contains(include, 'dnsResolvers'))) {
  dependsOn: [ virtualNetworks ]
  name: '${deployment.name}-dnsr-${padLeft(index, 3, '0')}'
  params: {
    location: (resolver.?location ?? deployment.location)
    name: (resolver.?name ?? 'dnsr${padLeft(index, 5, '0')}')
    properties: {
      inboundEndpoints: resolver.inboundEndpoints
      outboundEndpoints: resolver.outboundEndpoints
      virtualNetwork: resolver.virtualNetwork
    }
    tags: (resolver.?tags ?? tags)
  }
}]
module keyVaults 'br/bytrc:microsoft/key-vault/vaults:0.0.0' = [for (vault, index) in (properties.?keyVaults ?? []): if (!contains(exclude, 'keyVaults') && (empty(include) || contains(include, 'keyVaults'))) {
  name: '${deployment.name}-kv-${padLeft(index, 3, '0')}'
  params: {
    location: (vault.?location ?? deployment.location)
    name: (vault.?name ?? 'kv${padLeft(index, 5, '0')}')
    properties: {
      firewallRules: (vault.?firewallRules ?? null)
      isAllowTrustedMicrosoftServicesEnabled: (vault.?isAllowTrustedMicrosoftServicesEnabled ?? null)
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
module networkInterfaces 'br/bytrc:microsoft/network/network-interfaces:0.0.0' = [for (interface, index) in (properties.?networkInterfaces ?? []): if (!contains(exclude, 'networkInterfaces') && (empty(include) || contains(include, 'networkInterfaces'))) {
  dependsOn: [
    applicationSecurityGroups
    networkSecurityGroups
    publicIpAddresses
    publicIpPrefixes
  ]
  name: '${deployment.name}-nic-${padLeft(index, 3, '0')}'
  params: {
    location: (interface.?location ?? deployment.location)
    name: (interface.?name ?? 'nic${padLeft(index, 5, '0')}')
    properties: {
      dnsServers: (interface.?dnsServers ?? null)
      ipConfigurations: interface.ipConfigurations
      isAcceleratedNetworkingEnabled: (interface.?isAcceleratedNetworkingEnabled ?? null)
      isIpForwardingEnabled: (interface.?isIpForwardingEnabled ?? null)
      isTcpStateTrackingEnabled: (interface.?isTcpStateTrackingEnabled ?? null)
      networkSecurityGroup: (interface.?networkSecurityGroup ?? null)
      publicIpAddress: (interface.?publicIpAddress ?? null)
    }
    tags: (interface.?tags ?? tags)
  }
}]
module networkSecurityGroups 'br/bytrc:microsoft/network/network-security-groups:0.0.0' = [for (group, index) in (properties.?networkSecurityGroups ?? []): if (!contains(exclude, 'networkSecurityGroups') && (empty(include) || contains(include, 'networkSecurityGroups'))) {
  name: '${deployment.name}-nsg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'nsg${padLeft(index, 5, '0')}')
    properties: {
      securityRules: (group.?securityRules ?? null)
    }
    tags: (group.?tags ?? tags)
  }
}]
module proximityPlacementGroups 'br/bytrc:microsoft/compute/proximity-placement-groups:0.0.0' = [for (group, index) in (properties.?proximityPlacementGroups ?? []): if (!contains(exclude, 'proximityPlacementGroups') && (empty(include) || contains(include, 'proximityPlacementGroups'))) {
  name: '${deployment.name}-ppg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.?location ?? deployment.location)
    name: (group.?name ?? 'ppg${padLeft(index, 5, '0')}')
    tags: (group.?tags ?? tags)
  }
}]
module publicIpAddresses 'br/bytrc:microsoft/network/public-ip-addresses:0.0.0' = [for (address, index) in (properties.?publicIpAddresses ?? []): if (!contains(exclude, 'publicIpAddresses') && (empty(include) || contains(include, 'publicIpAddresses'))) {
  dependsOn: [ publicIpPrefixes ]
  name: '${deployment.name}-pipa-${padLeft(index, 3, '0')}'
  params: {
    location: (address.?location ?? deployment.location)
    name: (address.?name ?? 'pipa${padLeft(index, 5, '0')}')
    properties: {
      allocationMethod: (address.?allocationMethod ?? null)
      deleteOption: (address.?deleteOption ?? null)
      idleTimeoutInMinutes: (address.?idleTimeoutInMinutes ?? null)
      prefix: (address.?prefix ?? null)
      sku: address.sku
      version: (address.?version ?? null)
    }
    tags: (address.?tags ?? tags)
  }
}]
module publicIpPrefixes 'br/bytrc:microsoft/network/public-ip-prefixes:0.0.0' = [for (prefix, index) in (properties.?publicIpPrefixes ?? []): if (!contains(exclude, 'publicIpPrefixes') && (empty(include) || contains(include, 'publicIpPrefixes'))) {
  name: '${deployment.name}-pipp-${padLeft(index, 3, '0')}'
  params: {
    location: (prefix.?location ?? deployment.location)
    name: (prefix.?name ?? 'pipp${padLeft(index, 5, '0')}')
    properties: {
      customPrefix: (prefix.?customPrefix ?? null)
      length: prefix.length
      natGateway: (prefix.?natGateway ?? null)
      sku: prefix.sku
      version: (prefix.?version ?? null)
    }
    tags: (prefix.?tags ?? tags)
  }
}]
module routeTables 'br/bytrc:microsoft/network/route-tables:0.0.0' = [for (table, index) in (properties.?routeTables ?? []): if (!contains(exclude, 'routeTables') && (empty(include) || contains(include, 'routeTables'))) {
  name: '${deployment.name}-rt-${padLeft(index, 3, '0')}'
  params: {
    location: (table.?location ?? deployment.location)
    name: (table.?name ?? 'rt${padLeft(index, 5, '0')}')
    properties: {
      routes: (table.?routes ?? null)
    }
    tags: (table.?tags ?? tags)
  }
}]
module userManagedIdentities 'br/bytrc:microsoft/managed-identity/user-assigned-identities:0.0.0' = [for (identity, index) in (properties.?userManagedIdentities ?? []): if (!contains(exclude, 'userManagedIdentities') && (empty(include) || contains(include, 'userManagedIdentities'))) {
  name: '${deployment.name}-umi-${padLeft(index, 3, '0')}'
  params: {
    location: (identity.?location ?? deployment.location)
    name: (identity.?name ?? 'umi${padLeft(index, 5, '0')}')
    tags: (identity.?tags ?? tags)
  }
}]
module virtualMachines 'br/bytrc:microsoft/compute/virtual-machines:0.0.0' = [for (machine, index) in (properties.?virtualMachines ?? []): if (!contains(exclude, 'virtualMachines') && (empty(include) || contains(include, 'virtualMachines'))) {
  dependsOn: [
    applicationSecurityGroups
    availabilitySets
    capacityReservationGroups
    computeGalleries
    diskEncryptionSets
    keyVaults
    networkInterfaces
    networkSecurityGroups
    proximityPlacementGroups
    publicIpAddresses
    publicIpPrefixes
    routeTables
    userManagedIdentities
    virtualNetworks
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
module virtualNetworks 'br/bytrc:microsoft/network/virtual-networks:0.0.0' = [for (network, index) in (properties.?virtualNetworks ?? []): if (!contains(exclude, 'virtualNetworks') && (empty(include) || contains(include, 'virtualNetworks'))) {
  dependsOn: [
    applicationSecurityGroups
    networkSecurityGroups
    routeTables
  ]
  name: '${deployment.name}-vnet-${padLeft(index, 3, '0')}'
  params: {
    location: (network.?location ?? deployment.location)
    name: (network.?name ?? 'vnet${padLeft(index, 5, '0')}')
    properties: {
      addressPrefixes: network.addressPrefixes
      ddosProtectionPlan: (network.?ddosProtectionPlan ?? null)
      dnsServers: (network.?dnsServers ?? null)
      subnets: network.subnets
    }
    tags: (network.?tags ?? tags)
  }
}]
