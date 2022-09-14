@description('An array of CNAME records that will be created within the Azure DNS Zone.')
param cnameRecords array = []
@description('Specifies the name of the Azure DNS Zone.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure DNS Zone.')
param tags object = {}
@description('An array of TXT records that will be created within the Azure DNS Zone.')
param txtRecords array = []

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
    location: 'global'
    name: name
    properties: {
        zoneType: 'Public'
    }
    tags: tags
}

resource cnameRecordsCopy 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = [for record in cnameRecords: {
    name: record.name
    parent: dnsZone
    properties: {
        CNAMERecord: {
            cname: record.alias
        }
        metadata: union({ metadata: {} }, record).metadata
        TTL: union({ timeToLiveInSeconds: 3600 }, record).timeToLiveInSeconds
    }
}]

resource txtRecordsCopy 'Microsoft.Network/dnsZones/TXT@2018-05-01' = [for record in txtRecords: {
    name: record.name
    parent: dnsZone
    properties: {
        metadata: union({ metadata: {} }, record).metadata
        TTL: union({ timeToLiveInSeconds: 3600 }, record).timeToLiveInSeconds
        TXTRecords: [for entry in union({ values: [ [ union({ value: null }, record).value ] ] }, record).values: {
            value: entry
        }]
    }
}]
