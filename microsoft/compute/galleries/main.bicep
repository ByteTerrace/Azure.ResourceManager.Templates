param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var imageDefinitions = sort(items(properties.?imageDefinitions ?? {}), (x, y) => (x.key < y.key))
var imageDefinitionsVersions = sort(flatten(map(range(0, length(imageDefinitions)), index => map(items(imageDefinitions[index].value.?versions ?? {}), version => {
  key: version.key
  value: {
    imageIndex: index
    isExcludedFromLatest: (version.value.?isExcludedFromLatest ?? null)
    replication: (version.value.?replication ?? null)
    source: version.value.source
  }
}))), (x, y) => (x.key < y.key))
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
  name: definition.key
  parent: gallery
  properties: {
    architecture: (definition.value.?architecture ?? 'x64')
    description: (definition.value.?description ?? null)
    features: union((contains(definition.value, 'isAcceleratedNetworkingSupported') ? [{
      name: 'IsAcceleratedNetworkSupported'
      value: string(definition.value.isAcceleratedNetworkingSupported)
    }] : []), (contains(definition.value, 'IsHibernateSupported') ? [{
      name: 'IsHibernateSupported'
      value: string(definition.value.isHibernateSupported)
    }] : []), (('standard' != toLower(definition.value.?securityType ?? 'standard')) ? [{
      name: 'SecurityType'
      value: definition.value.securityType
    }] : []))
    hyperVGeneration: (definition.value.?generation ?? 'V2')
    identifier: {
      offer: definition.value.identifier.offer
      publisher: definition.value.identifier.publisher
      sku: definition.value.identifier.sku
    }
    osState: definition.value.operatingSystem.state
    osType: definition.value.operatingSystem.type
  }
  tags: (definition.value.?tags ?? tags)
}]
resource imagesVersions 'Microsoft.Compute/galleries/images/versions@2022-03-03' = [for (version, index) in imageDefinitionsVersions: {
  location: location
  name: version.key
  parent: images[version.value.imageIndex]
  properties: {
    publishingProfile: {
      excludeFromLatest: version.value.isExcludedFromLatest
      replicaCount: (version.value.replication.?count ?? null)
      replicationMode: (version.value.replication.?mode ?? 'Full')
      targetRegions: [for region in items(version.value.replication.?regions ?? {}): {
        encryption: (empty(region.value.?diskEncryptionSet ?? {}) ? null : {
          dataDiskImages: map(virtualMachinesRef[index].properties.storageProfile.dataDisks, disk => {
            diskEncryptionSetId: resourceId((region.value.diskEncryptionSet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Compute/diskEncryptionSets', region.value.diskEncryptionSet.name)
            lun: disk.lun
          })
          osDiskImage: {
            diskEncryptionSetId: resourceId((region.value.diskEncryptionSet.?resourceGroupName ?? resourceGroupName), 'Microsoft.Compute/diskEncryptionSets', region.value.diskEncryptionSet.name)
          }
        })
        excludeFromLatest: (region.value.?isExcludedFromLatest ?? version.value.isExcludedFromLatest)
        name: region.key
        storageAccountType: (region.value.?storageAccountType ?? 'Standard_LRS')
      }]
    }
    storageProfile: {
      source: {
        id: virtualMachinesRef[index].id
      }
    }
  }
}]
resource virtualMachinesRef 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [for machine in map(imageDefinitionsVersions, version => version.value.source.virtualMachine): {
  name: machine.name
  scope: resourceGroup((machine.?subscriptionId ?? subscriptionId), (machine.?resourceGroupName ?? resourceGroupName))
}]
