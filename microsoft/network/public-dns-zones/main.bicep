param name string
@secure()
param properties object
param tags object = {}

resource aRecordEntries 'Microsoft.Network/dnsZones/A@2018-05-01' = [for record in items(properties.?aRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    ARecords: [for address in record.value.ipAddresses: {
      ipv4Address: address
    }]
    metadata: (record.value.?metadata ?? null)
    targetResource: null
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource aaaaRecordEntries 'Microsoft.Network/dnsZones/AAAA@2018-05-01' = [for record in items(properties.?aaaaRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    AAAARecords: [for address in record.value.ipAddresses: {
      ipv6Address: address
    }]
    metadata: (record.value.?metadata ?? null)
    targetResource: null
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource cnameRecordEntries 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = [for record in items(properties.?cnameRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    CNAMERecord: {
      cname: record.value.alias
    }
    metadata: (record.value.?metadata ?? null)
    targetResource: null
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource mxRecordEntries 'Microsoft.Network/dnsZones/MX@2018-05-01' = [for record in items(properties.?mxRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    MXRecords: [for exchange in record.value.exchanges: {
      exchange: exchange.domainName
      preference: exchange.preference
    }]
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource publicDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  location: 'global'
  name: name
  properties: {
    zoneType: 'Public'
  }
  tags: tags
}
resource ptrRecordEntries 'Microsoft.Network/dnsZones/PTR@2018-05-01' = [for record in items(properties.?ptrRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    PTRRecords: [for name in record.value.domainNames: {
      ptrdname: name
    }]
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource srvRecordEntries 'Microsoft.Network/dnsZones/SRV@2018-05-01' = [for record in items(properties.?srvRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    SRVRecords: [for service in record.value.services: {
      port: service.port
      priority: service.priority
      target: service.target
      weight: service.weight
    }]
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
  }
}]
resource txtRecordEntries 'Microsoft.Network/dnsZones/TXT@2018-05-01' = [for record in items(properties.?txtRecords ?? {}): {
  name: record.key
  parent: publicDnsZone
  properties: {
    metadata: (record.value.?metadata ?? null)
    TTL: (record.value.?timeToLiveInSeconds ?? 10)
    TXTRecords: [for value in record.value.values: {
      value: value
    }]
  }
}]
