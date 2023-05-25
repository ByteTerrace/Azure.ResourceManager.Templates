param location string = resourceGroup().location
param name string
@secure()
param properties object = {}
param tags object = {}

var imageDefinitions = (properties.?imageDefinitions ?? [])
var imageDefinitionsVersions = flatten(map(range(0, length(imageDefinitions)), index => map((imageDefinitions[index].?versions ?? []), version => {
  imageIndex: index
  isExcludedFromLatest: (version.?isExcludedFromLatest ?? false)
  name: version.name
  replication: (version.?replication ?? null)
  source: version.source
})))
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  location: location
  name: name
  properties: {
    description: (properties.?description ?? null)
  }
  tags: tags
}
resource images 'Microsoft.Compute/galleries/images@2022-03-03' = [for definition in imageDefinitions: {
  location: location
  name: definition.name
  parent: gallery
  properties: {
    architecture: (definition.?architecture ?? 'x64')
    description: (definition.?description ?? null)
    features: union((contains(definition, 'isAcceleratedNetworkingSupported') ? [{
      name: 'IsAcceleratedNetworkSupported'
      value: string(definition.isAcceleratedNetworkingSupported)
    }] : []), (contains(definition, 'IsHibernateSupported') ? [{
      name: 'IsHibernateSupported'
      value: string(definition.isHibernateSupported)
    }] : []), (('standard' != toLower(definition.?securityType ?? 'standard')) ? [{
      name: 'SecurityType'
      value: definition.securityType
    }] : []))
    hyperVGeneration: (definition.?generation ?? 'V2')
    identifier: {
      offer: definition.identifier.offer
      publisher: definition.identifier.publisher
      sku: definition.identifier.sku
    }
    osState: definition.operatingSystem.state
    osType: definition.operatingSystem.type
  }
  tags: (definition.?tags ?? tags)
}]
resource imagesVersions 'Microsoft.Compute/galleries/images/versions@2022-03-03' = [for (version, index) in imageDefinitionsVersions: {
  location: location
  name: version.name
  parent: images[version.imageIndex]
  properties: {
    publishingProfile: {
      excludeFromLatest: version.isExcludedFromLatest
      replicaCount: (version.replication.?count ?? null)
      replicationMode: (version.replication.?mode ?? 'Full')
      targetRegions: [for region in items(version.replication.?regions ?? {}): {
        encryption: (empty(region.value.?diskEncryptionSet ?? {}) ? null : {
          dataDiskImages: map(virtualMachines[index].properties.storageProfile.dataDisks, disk => {
            diskEncryptionSetId: resourceId((region.value.diskEncryptionSet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Compute/diskEncryptionSets', region.value.diskEncryptionSet.name)
            lun: disk.lun
          })
          osDiskImage: {
            diskEncryptionSetId: resourceId((region.value.diskEncryptionSet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Compute/diskEncryptionSets', region.value.diskEncryptionSet.name)
          }
        })
        excludeFromLatest: (region.value.?isExcludedFromLatest ?? version.isExcludedFromLatest)
        name: region.key
        storageAccountType: (region.value.?storageAccountType ?? 'Standard_LRS')
      }]
    }
    storageProfile: {
      source: {
        id: virtualMachines[index].id
      }
    }
  }
}]
resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [for machine in map(imageDefinitionsVersions, version => version.source.virtualMachine): {
  name: machine.name
  scope: resourceGroup((machine.?subscriptionId ?? subscriptionId), (machine.?resourceGroupName ?? resourceGroupName))
}]
