param name string
@secure()
param properties object
param tags object = {}

var linkedVirtualNetworks = items(properties.?virtualNetworks ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource aRecordEntries 'Microsoft.Network/privateDnsZones/A@2020-06-01' = [for record in items(properties.?aRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    aRecords: [for address in record.value.ipAddresses: { ipv4Address: address } ]
    metadata: (record.value.?metadata ?? null)
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource aaaaRecordEntries 'Microsoft.Network/privateDnsZones/AAAA@2020-06-01' = [for record in items(properties.?aaaaRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    aaaaRecords: record.value.ipAddresses
    metadata: (record.value.?metadata ?? null)
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource cnameRecordEntries 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = [for record in items(properties.?cnameRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    cnameRecord: record.value.alias
    metadata: (record.value.?metadata ?? null)
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource mxRecordEntries 'Microsoft.Network/privateDnsZones/MX@2020-06-01' = [for record in items(properties.?mxRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    mxRecords: record.value.exchanges
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: name
  tags: tags
}
resource ptrRecordEntries 'Microsoft.Network/privateDnsZones/PTR@2020-06-01' = [for record in items(properties.?ptrRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    ptrRecords: record.value.domainNames
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource srvRecordEntries 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = [for record in items(properties.?srvRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    srvRecords: [for service in record.value.services: {
      port: service.port
      priority: service.priority
      target: service.target
      weight: service.weight
    }]
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource txtRecordEntries 'Microsoft.Network/privateDnsZones/TXT@2020-06-01' = [for record in items(properties.?txtRecords ?? {}): {
  name: record.key
  parent: privateDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    ttl: (record.value.?timeToLiveInSeconds ?? 10)
    txtRecords: record.value.values
  }
}]
resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (network, index) in linkedVirtualNetworks: {
  location: 'global'
  name: guid(privateDnsZone.id, virtualNetworks[index].id)
  parent: privateDnsZone
  properties: {
    registrationEnabled: (network.value.?isAutomaticVmRegistrationEnabled ?? false)
    virtualNetwork: { id: virtualNetworks[index].id }
  }
}]
resource virtualNetworks 'Microsoft.Network/virtualNetworks@2022-11-01' existing = [for network in linkedVirtualNetworks: {
  name: network.key
  scope: resourceGroup((network.value.?subscriptionId ?? subscriptionId), (network.value.?resourceGroupName ?? resourceGroupName))
}]
