@description('Specifies the location in which the Azure Network Security Group resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Network Security Group.')
param name string
@description('An array of security rules that will be assigned to the Azure Network Security Group.')
param securityRules array = []
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Network Security Group.')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
    location: location
    name: name
    properties: {
        securityRules: [for (rule, index) in securityRules: {
            name: union({ name: '${rule.access}-${rule.direction}-${uniqueString(join(rule.destination.addressPrefixes, ', '), join(rule.destination.ports, ', '), join(rule.source.addressPrefixes, ', '), join(rule.source.ports, ', '))}' }, rule).name
            properties: {
                access: rule.access
                description: union({ description: '' }, rule).description
                destinationAddressPrefix: (1 == length(rule.destination.addressPrefixes)) ? first(rule.destination.addressPrefixes) : null
                destinationAddressPrefixes: (1 < length(rule.destination.addressPrefixes)) ? rule.destination.addressPrefixes : null
                destinationPortRange: (1 == length(rule.destination.ports)) ? first(rule.destination.ports) : null
                destinationPortRanges: (1 < length(rule.destination.ports)) ? rule.destination.ports : null
                direction: rule.direction
                priority: union({ priority: (2100 - (length(securityRules) + index)) }, rule).priority
                protocol: rule.protocol
                sourceAddressPrefix: (1 == length(rule.source.addressPrefixes)) ? first(rule.source.addressPrefixes) : null
                sourceAddressPrefixes: (1 < length(rule.source.addressPrefixes)) ? rule.source.addressPrefixes : null
                sourceApplicationSecurityGroups: union({ source: { applicationSecurityGroups: [] } }, rule).source.applicationSecurityGroups
                sourcePortRange: (1 == length(rule.source.ports)) ? first(rule.source.ports) : null
                sourcePortRanges: (1 < length(rule.source.ports)) ? rule.source.ports : null
            }
        }]
    }
    tags: tags
}
