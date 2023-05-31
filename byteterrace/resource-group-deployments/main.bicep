type applicationSecurityGroup = {
  location: string?
  tags: object?
}
type availabilitySet = {
  faultDomainCount: int
  location: string?
  proximityPlacementGroup: resourceReference?
  tags: object?
  updateDomainCount: int
}
type capacityReservationGroup = {
  availabilityZones: string[]?
  location: string?
  reservations: {
    *: {
      availabilityZones: string[]?
      sku: resourceSku
      tags: object?
    }
  }?
  tags: object?
}
type computeGallery = {
  description: string?
  imageDefinitions: {
    *: {
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
      operatingSystem: {
        state: ('Generalized' | 'Specialized')
        type: ('Linux' | 'Windows')
      }
      securityType: ('ConfidentialVM' | 'ConfidentialVmSupported' | 'Standard' | 'TrustedLaunch' | 'TrustedLaunchSupported')?
      tags: object?
    }
  }?
  location: string?
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
  tags: object?
}
type dnsResolver = {
  inboundEndpoints: {
    *: {
      privateIpAddress: {
        subnet: {
          name: string
        }
        value: string?
      }
      tags: object?
    }
  }?
  location: string?
  outboundEndpoints: {
    *: {
      subnet: {
        name: string
      }
      tags: object?
    }
  }?
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
  roleAssignments: array?
  sku: resourceSku
  softDeleteRetentionInDays: int?
  tags: object?
  tenantId: string?
  virtualNetworkRules: virtualNetworkRule[]?
}
type managedDiskStorageAccountType = ('Premium_LRS' | 'Premium_ZRS' | 'PremiumV2_LRS' | 'Standard_LRS' | 'StandardSSD_LRS' | 'StandardSSD_ZRS' | 'UltraSSD_LRS')
type natGateway = {
  idleTimeoutInMinutes: int?
  location: string?
  publicIpAddresses: { *: resourceReference }?
  publicIpPrefixes: { *: resourceReference }?
  sku: resourceSku
  tags: object?
}
type networkInterface = {
  dnsServers: string[]?
  ipConfigurations: {
    *: {
      isPrimary: bool?
      privateIpAddress: {
        subnet: subnetReference
        value: string?
        version: ('IPv4' | 'IPv6')?
      }
      publicIpAddress: resourceReference?
    }
  }
  isAcceleratedNetworkingEnabled: bool?
  isIpForwardingEnabled: bool?
  isTcpStateTrackingEnabled: bool?
  location: string?
  networkSecurityGroup: resourceReference?
  publicIpAddress: resourceReference?
  tags: object?
}
type networkSecurityGroup = {
  location: string?
  securityRules: {
    *: {
      access: ('Allow' | 'Deny')
      description: string?
      destination: {
        addressPrefixes: string[]
        applicationSecurityGroups: resourceReference[]?
        ports: string[]
      }
      direction: ('Inbound' | 'Outbound')
      protocol: ('*' | 'Ah' | 'Esp' | 'Icmp' | 'Tcp' | 'Udp')
      source: {
        addressPrefixes: string[]
        applicationSecurityGroups: resourceReference[]?
        ports: string[]
      }
    }
  }?
  tags: object?
}
type propertiesInfo = {
  applicationSecurityGroups: { *: applicationSecurityGroup }?
  availabilitySets: { *: availabilitySet }?
  capacityReservationGroups: { *: capacityReservationGroup }?
  computeGalleries: { *: computeGallery }?
  containerRegistries: { *: containerRegistry }?
  diskEncryptionSets: { *: diskEncryptionSet }?
  dnsResolvers: { *: dnsResolver }?
  keyVaults: { *: keyVault }?
  natGateways: { *: natGateway }?
  networkInterfaces: { *: networkInterface }?
  networkSecurityGroups: { *: networkSecurityGroup }?
  proximityPlacementGroups: { *: proximityPlacementGroup }?
  publicIpAddresses: { *: publicIpAddress }?
  publicIpPrefixes: { *: publicIpPrefix }?
  routeTables: { *: routeTable }?
  userManagedIdentities: { *: userManagedIdentity }?
  virtualMachines: { *: virtualMachine }?
  virtualNetworks: { *: virtualNetwork }?
}
type proximityPlacementGroup = {
  location: string?
  tags: object?
}
type publicIpAddress = {
  allocationMethod: ('Dynamic' | 'Static')?
  deleteOption: ('Delete' | 'Detach')?
  idleTimeoutInMinutes: int?
  location: string?
  prefix: resourceReference?
  sku: resourceSku
  tags: object?
  version: ('IPv4' | 'IPV6')?
}
type publicIpPrefix = {
  customPrefix: resourceReference?
  length: int
  location: string?
  sku: resourceSku
  tags: object?
  version: ('IPv4' | 'IPV6')?
}
type resourceIdentity = {
  type: string?
  userAssignedIdentities: resourceReference[]?
}
type resourceReference = {
  name: string?
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
  routes: {
    *: {
      addressPrefix: string
      name: string
      nextHopIpAddress: string?
    }
  }?
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
  certificates: {
    *: {
      isExportable: bool?
      keyVault: resourceReference
    }
  }?
  dataDisks: {
    *: {
      cachingMode: ('None' | 'ReadOnly' | 'ReadWrite')?
      createOption: ('Attach' | 'Empty' | 'FromImage')?
      deleteOption: ('Delete' | 'Detach')?
      isWriteAcceleratorEnabled: bool?
      sizeInGigabytes: int
      storageAccountType: managedDiskStorageAccountType?
    }
  }?
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
  networkInterfaces: {
    *: {
      deleteOption: ('Delete' | 'Detach')?
      dnsServers: string[]?
      dscpConfiguration: resourceReference?
      isAcceleratedNetworkingEnabled: bool?
      isExisting: bool?
      isFpgaNetworkingEnabled: bool?
      isIpForwardingEnabled: bool?
      isPrimary: bool?
      isTcpStateTrackingEnabled: bool?
      ipConfigurations: {
        *: {
          applicationGateways: {
            *: {
              backEndAddressPoolNames: string[]
              resourceGroupName: string?
            }
          }?
          applicationSecurityGroups: {
            *: {
              resourceGroupName: string?
            }
          }?
          isPrimary: bool?
          loadBalancers: {
            *: {
              backEndAddressPoolNames: string[]
              resourceGroupName: string?
            }
          }?
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
        }
      }?
      networkSecurityGroup: resourceReference?
      resourceGroupName: string?
      subscriptionId: string?
    }
  }
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
    *: {
      blobPath: string?
      containerName: string?
      errorBlobPath: string?
      errorBlobUri: string?
      outputBlobPath: string?
      outputBlobUri: string?
      parameters: object?
      storageAccount: resourceReference?
      tags: object?
      timeoutInSeconds: int?
      uri: string?
      value: string?
    }
  }?
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
  subnets: {
    *: {
      addressPrefixes: string[]
      delegations: string[]?
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
        *: {
          locations: string[]?
        }
      }?
    }
  }?
  tags: object?
}
type virtualNetworkRule = {
  subnet: subnetReference
}
type userManagedIdentity = {
  location: string?
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

module applicationSecurityGroups 'br/bytrc:microsoft/network/application-security-groups:0.0.0' = [for (group, index) in items(properties.?applicationSecurityGroups ?? {}): if (!contains(exclude, 'applicationSecurityGroups') && (empty(include) || contains(include, 'applicationSecurityGroups'))) {
  name: '${deployment.name}-asg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.value.?location ?? deployment.location)
    name: group.key
    tags: (group.value.?tags ?? tags)
  }
}]
module availabilitySets 'br/bytrc:microsoft/compute/availability-sets:0.0.0' = [for (set, index) in items(properties.?availabilitySets ?? {}): if (!contains(exclude, 'availabilitySets') && (empty(include) || contains(include, 'availabilitySets'))) {
  dependsOn: [ proximityPlacementGroups ]
  name: '${deployment.name}-as-${padLeft(index, 3, '0')}'
  params: {
    location: (set.value.?location ?? deployment.location)
    name: set.key
    properties: {
      faultDomainCount: set.value.faultDomainCount
      proximityPlacementGroup: (set.value.?proximityPlacementGroup ?? null)
      updateDomainCount: set.value.updateDomainCount
    }
    tags: (set.value.?tags ?? tags)
  }
}]
module capacityReservationGroups 'br/bytrc:microsoft/compute/capacity-reservation-groups:0.0.0' = [for (group, index) in items(properties.?capacityReservationGroups ?? {}): if (!contains(exclude, 'capacityReservationGroups') && (empty(include) || contains(include, 'capacityReservationGroups'))) {
  name: '${deployment.name}-crg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.value.?location ?? deployment.location)
    name: group.key
    properties: {
      availabilityZones: (group.value.?availabilityZones ?? null)
      reservations: (group.value.?reservations ?? null)
    }
    tags: (group.value.?tags ?? tags)
  }
}]
module computeGalleries 'br/bytrc:microsoft/compute/galleries:0.0.0' = [for (gallery, index) in items(properties.?computeGalleries ?? {}): if (!contains(exclude, 'computeGalleries') && (empty(include) || contains(include, 'computeGalleries'))) {
  name: '${deployment.name}-cg-${padLeft(index, 3, '0')}'
  params: {
    location: (gallery.value.?location ?? deployment.location)
    name: gallery.key
    properties: {
      description: (gallery.value.?description ?? null)
      imageDefinitions: (gallery.value.?imageDefinitions ?? null)
    }
    tags: (gallery.value.?tags ?? tags)
  }
}]
module containerRegistries 'br/bytrc:microsoft/container-registry/registries:0.0.0' = [for (registry, index) in items(properties.?containerRegistries ?? {}): if (!contains(exclude, 'containerRegistries') && (empty(include) || contains(include, 'containerRegistries'))) {
  dependsOn: [
    keyVaults
    userManagedIdentities
  ]
  name: '${deployment.name}-cr-${padLeft(index, 3, '0')}'
  params: {
    location: (registry.value.?location ?? deployment.location)
    name: registry.key
    properties: {
      firewallRules: (registry.value.?firewallRules ?? null)
      identity: (registry.value.?identity ?? null)
      isAllowTrustedMicrosoftServicesEnabled: (registry.value.?isAllowTrustedMicrosoftServicesEnabled ?? null)
      isAnonymousPullEnabled: (registry.value.?isAnonymousPullEnabled ?? null)
      isContentTrustPolicyEnabled: (registry.value.?isContentTrustPolicyEnabled ?? null)
      isDedicatedDataEndpointEnabled: (registry.value.?isDedicatedDataEndpointEnabled ?? null)
      isExportPolicyEnabled: (registry.value.?isExportPolicyEnabled ?? null)
      isPublicNetworkAccessEnabled: (registry.value.?isPublicNetworkAccessEnabled ?? null)
      isQuarantinePolicyEnabled: (registry.value.?isQuarantinePolicyEnabled ?? null)
      isZoneRedundancyEnabled: (registry.value.?isZoneRedundancyEnabled ?? null)
      roleAssignments: (registry.value.?roleAssignments ?? null)
      sku: registry.value.sku
    }
    tags: (registry.value.?tags ?? tags)
  }
}]
module diskEncryptionSets 'br/bytrc:microsoft/compute/disk-encryption-sets:0.0.0' = [for (set, index) in items(properties.?diskEncryptionSets ?? {}): if (!contains(exclude, 'diskEncryptionSets') && (empty(include) || contains(include, 'diskEncryptionSets'))) {
  dependsOn: [
    keyVaults
    userManagedIdentities
  ]
  name: '${deployment.name}-des-${padLeft(index, 3, '0')}'
  params: {
    location: (set.value.?location ?? deployment.location)
    name: set.key
    properties: {
      encryptionType: set.value.encryptionType
      identity: (set.value.?identity ?? null)
      keyName: set.value.keyName
      keyVault: set.value.keyVault
    }
    tags: (set.value.?tags ?? tags)
  }
}]
module dnsResolvers 'br/bytrc:microsoft/network/dns-resolvers:0.0.0' = [for (resolver, index) in items(properties.?dnsResolvers ?? {}): if (!contains(exclude, 'dnsResolvers') && (empty(include) || contains(include, 'dnsResolvers'))) {
  dependsOn: [ virtualNetworks ]
  name: '${deployment.name}-dnsr-${padLeft(index, 3, '0')}'
  params: {
    location: (resolver.value.?location ?? deployment.location)
    name: resolver.key
    properties: {
      inboundEndpoints: resolver.value.inboundEndpoints
      outboundEndpoints: resolver.value.outboundEndpoints
      virtualNetwork: resolver.value.virtualNetwork
    }
    tags: (resolver.value.?tags ?? tags)
  }
}]
module keyVaults 'br/bytrc:microsoft/key-vault/vaults:0.0.0' = [for (vault, index) in items(properties.?keyVaults ?? {}): if (!contains(exclude, 'keyVaults') && (empty(include) || contains(include, 'keyVaults'))) {
  name: '${deployment.name}-kv-${padLeft(index, 3, '0')}'
  params: {
    location: (vault.value.?location ?? deployment.location)
    name: vault.key
    properties: {
      firewallRules: (vault.value.?firewallRules ?? null)
      isAllowTrustedMicrosoftServicesEnabled: (vault.value.?isAllowTrustedMicrosoftServicesEnabled ?? null)
      isDiskEncryptionEnabled: (vault.value.?isDiskEncryptionEnabled ?? null)
      isPublicNetworkAccessEnabled: (vault.value.?isPublicNetworkAccessEnabled ?? null)
      isPurgeProtectionEnabled: (vault.value.?isPurgeProtectionEnabled ?? null)
      isTemplateDeploymentEnabled: (vault.value.?isTemplateDeploymentEnabled ?? null)
      isVirtualMachineDeploymentEnabled: (vault.value.?isVirtualMachineDeploymentEnabled ?? null)
      roleAssignments: (vault.value.?roleAssignments ?? null)
      sku: vault.value.sku
      softDeleteRetentionInDays: (vault.value.?softDeleteRetentionInDays ?? null)
      tenantId: (vault.value.?tenantId ?? null)
      virtualNetworkRules: (vault.value.?virtualNetworkRules ?? null)
    }
    tags: (vault.value.?tags ?? tags)
  }
}]
module natGateways 'br/bytrc:microsoft/network/nat-gateways:0.0.0' = [for (gateway, index) in items(properties.?natGateways ?? {}): if (!contains(exclude, 'natGateways') && (empty(include) || contains(include, 'natGateways'))) {
  dependsOn: [
    publicIpAddresses
    publicIpPrefixes
  ]
  name: '${deployment.name}-nat-${padLeft(index, 3, '0')}'
  params: {
    location: (gateway.value.?location ?? deployment.location)
    name: gateway.key
    properties: {
      idleTimeoutInMinutes: (gateway.value.?idleTimeoutInMinutes ?? null)
      publicIpAddresses: (gateway.value.?publicIpAddresses ?? null)
      publicIpPrefixes: (gateway.value.?publicIpPrefixes ?? null)
      sku: gateway.value.sku
    }
    tags: (gateway.value.?tags ?? tags)
  }
}]
module networkInterfaces 'br/bytrc:microsoft/network/network-interfaces:0.0.0' = [for (interface, index) in items(properties.?networkInterfaces ?? {}): if (!contains(exclude, 'networkInterfaces') && (empty(include) || contains(include, 'networkInterfaces'))) {
  dependsOn: [
    applicationSecurityGroups
    networkSecurityGroups
    publicIpAddresses
    publicIpPrefixes
    virtualNetworks
  ]
  name: '${deployment.name}-nic-${padLeft(index, 3, '0')}'
  params: {
    location: (interface.value.?location ?? deployment.location)
    name: interface.key
    properties: {
      dnsServers: (interface.value.?dnsServers ?? null)
      ipConfigurations: interface.value.ipConfigurations
      isAcceleratedNetworkingEnabled: (interface.value.?isAcceleratedNetworkingEnabled ?? null)
      isIpForwardingEnabled: (interface.value.?isIpForwardingEnabled ?? null)
      isTcpStateTrackingEnabled: (interface.value.?isTcpStateTrackingEnabled ?? null)
      networkSecurityGroup: (interface.value.?networkSecurityGroup ?? null)
      publicIpAddress: (interface.value.?publicIpAddress ?? null)
    }
    tags: (interface.value.?tags ?? tags)
  }
}]
module networkSecurityGroups 'br/bytrc:microsoft/network/network-security-groups:0.0.0' = [for (group, index) in items(properties.?networkSecurityGroups ?? {}): if (!contains(exclude, 'networkSecurityGroups') && (empty(include) || contains(include, 'networkSecurityGroups'))) {
  name: '${deployment.name}-nsg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.value.?location ?? deployment.location)
    name: group.key
    properties: {
      securityRules: (group.value.?securityRules ?? null)
    }
    tags: (group.value.?tags ?? tags)
  }
}]
module proximityPlacementGroups 'br/bytrc:microsoft/compute/proximity-placement-groups:0.0.0' = [for (group, index) in items(properties.?proximityPlacementGroups ?? {}): if (!contains(exclude, 'proximityPlacementGroups') && (empty(include) || contains(include, 'proximityPlacementGroups'))) {
  name: '${deployment.name}-ppg-${padLeft(index, 3, '0')}'
  params: {
    location: (group.value.?location ?? deployment.location)
    name: group.key
    tags: (group.value.?tags ?? tags)
  }
}]
module publicIpAddresses 'br/bytrc:microsoft/network/public-ip-addresses:0.0.0' = [for (address, index) in items(properties.?publicIpAddresses ?? {}): if (!contains(exclude, 'publicIpAddresses') && (empty(include) || contains(include, 'publicIpAddresses'))) {
  dependsOn: [ publicIpPrefixes ]
  name: '${deployment.name}-pipa-${padLeft(index, 3, '0')}'
  params: {
    location: (address.value.?location ?? deployment.location)
    name: address.key
    properties: {
      allocationMethod: (address.value.?allocationMethod ?? null)
      deleteOption: (address.value.?deleteOption ?? null)
      idleTimeoutInMinutes: (address.value.?idleTimeoutInMinutes ?? null)
      prefix: (address.value.?prefix ?? null)
      sku: address.value.sku
      version: (address.value.?version ?? null)
    }
    tags: (address.value.?tags ?? tags)
  }
}]
module publicIpPrefixes 'br/bytrc:microsoft/network/public-ip-prefixes:0.0.0' = [for (prefix, index) in items(properties.?publicIpPrefixes ?? {}): if (!contains(exclude, 'publicIpPrefixes') && (empty(include) || contains(include, 'publicIpPrefixes'))) {
  name: '${deployment.name}-pipp-${padLeft(index, 3, '0')}'
  params: {
    location: (prefix.value.?location ?? deployment.location)
    name: prefix.key
    properties: {
      customPrefix: (prefix.value.?customPrefix ?? null)
      length: prefix.value.length
      sku: prefix.value.sku
      version: (prefix.value.?version ?? null)
    }
    tags: (prefix.value.?tags ?? tags)
  }
}]
module routeTables 'br/bytrc:microsoft/network/route-tables:0.0.0' = [for (table, index) in items(properties.?routeTables ?? {}): if (!contains(exclude, 'routeTables') && (empty(include) || contains(include, 'routeTables'))) {
  name: '${deployment.name}-rt-${padLeft(index, 3, '0')}'
  params: {
    location: (table.value.?location ?? deployment.location)
    name: table.key
    properties: {
      routes: (table.value.?routes ?? null)
    }
    tags: (table.value.?tags ?? tags)
  }
}]
module userManagedIdentities 'br/bytrc:microsoft/managed-identity/user-assigned-identities:0.0.0' = [for (identity, index) in items(properties.?userManagedIdentities ?? {}): if (!contains(exclude, 'userManagedIdentities') && (empty(include) || contains(include, 'userManagedIdentities'))) {
  name: '${deployment.name}-umi-${padLeft(index, 3, '0')}'
  params: {
    location: (identity.value.?location ?? deployment.location)
    name: identity.key
    tags: (identity.value.?tags ?? tags)
  }
}]
module virtualMachines 'br/bytrc:microsoft/compute/virtual-machines:0.0.0' = [for (machine, index) in items(properties.?virtualMachines ?? {}): if (!contains(exclude, 'virtualMachines') && (empty(include) || contains(include, 'virtualMachines'))) {
  dependsOn: [
    applicationSecurityGroups
    availabilitySets
    capacityReservationGroups
    computeGalleries
    diskEncryptionSets
    keyVaults
    natGateways
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
    location: (machine.value.?location ?? deployment.location)
    name: machine.key
    properties: {
      automaticShutdown: (machine.value.?automaticShutdown ?? null)
      availabilitySet: (machine.value.?availabilitySet ?? null)
      bootDiagnostics: (machine.value.?bootDiagnostics ?? null)
      capacityReservationGroup: (machine.value.?capacityReservationGroup ?? null)
      certificates: (machine.value.?certificates ?? null)
      dataDisks: (machine.value.?dataDisks ?? null)
      diskEncryptionSet: (machine.value.?diskEncryptionSet ?? null)
      identity: (machine.value.?identity ?? null)
      imageReference: (machine.value.?imageReference ?? null)
      isEncryptionAtHostEnabled: (machine.value.?isEncryptionAtHostEnabled ?? null)
      isGuestAgentEnabled: (machine.value.?isGuestAgentEnabled ?? null)
      isHibernationEnabled: (machine.value.?isHibernationEnabled ?? null)
      isSecureBootEnabled: (machine.value.?isSecureBootEnabled ?? null)
      isUltraSsdEnabled: (machine.value.?isUltraSsdEnabled ?? null)
      isVirtualTrustedPlatformModuleEnabled: (machine.value.?isVirtualTrustedPlatformModuleEnabled ?? null)
      licenseType: (machine.value.?licenseType ?? null)
      networkInterfaces: machine.value.networkInterfaces
      operatingSystem: machine.value.operatingSystem
      proximityPlacementGroup: (machine.value.?proximityPlacementGroup ?? null)
      roleAssignments: (machine.value.?roleAssignments ?? null)
      scripts: (machine.value.?scripts ?? null)
      sku: machine.value.sku
      spotSettings: (machine.value.?spotSettings ?? null)
      virtualMachineScaleSet: (machine.value.?virtualMachineScaleSet ?? null)
    }
    tags: (machine.value.?tags ?? tags)
  }
}]
module virtualNetworks 'br/bytrc:microsoft/network/virtual-networks:0.0.0' = [for (network, index) in items(properties.?virtualNetworks ?? {}): if (!contains(exclude, 'virtualNetworks') && (empty(include) || contains(include, 'virtualNetworks'))) {
  dependsOn: [
    applicationSecurityGroups
    natGateways
    networkSecurityGroups
    routeTables
  ]
  name: '${deployment.name}-vnet-${padLeft(index, 3, '0')}'
  params: {
    location: (network.value.?location ?? deployment.location)
    name: network.key
    properties: {
      addressPrefixes: network.value.addressPrefixes
      ddosProtectionPlan: (network.value.?ddosProtectionPlan ?? null)
      dnsServers: (network.value.?dnsServers ?? null)
      subnets: network.value.subnets
    }
    tags: (network.value.?tags ?? tags)
  }
}]
