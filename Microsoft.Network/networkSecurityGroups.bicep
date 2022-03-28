@description('Specifies the location in which the Network Security Group resource(s) will be deployed.')
param location string
@maxLength(80)
@minLength(1)
@description('Specifies the name of the Network Security Group.')
param name string
@description('An array of security rules that will be assigned to the Azure Network Security Group.')
param securityRules array
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Virtual Network.')
param tags object

/*module sourceApplicationSecurityGroupsById '../resourceIdHelper.bicep' = [for rule in securityRules: {
    name: '${deployment().name}-${rule.name}'
    params: {
        resources: rule.source.applicationSecurityGroups
    }
}]*/

var defaults = {
    securityRule: {
        source: {
            applicationSecurityGroups: []
        }
    }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
    location: location
    name: name
    properties: {
        securityRules: [for (rule, index) in securityRules: {
            name: rule.name
            properties: {
                access: rule.access
                description: union({
                    description: ''
                }, rule).description
                destinationAddressPrefix: ((1 == length(rule.destination.addressPrefixes)) ? first(rule.destination.addressPrefixes) : null)
                destinationAddressPrefixes: ((1 < length(rule.destination.addressPrefixes)) ? rule.destination.addressPrefixes : null)
                destinationPortRange: ((1 == length(rule.destination.addressPrefixes)) ? first(rule.destination.ports) : null)
                destinationPortRanges: ((1 < length(rule.destination.addressPrefixes)) ? rule.destination.ports : null)
                direction: rule.direction
                priority: union({
                    priority: (4097 - (length(securityRules) + index))
                }, rule).priority
                protocol: rule.protocol
                sourceAddressPrefix: ((1 == length(rule.source.addressPrefixes)) ? first(rule.source.addressPrefixes) : null)
                sourceAddressPrefixes: ((1 < length(rule.source.addressPrefixes)) ? rule.source.addressPrefixes : null)
                sourceApplicationSecurityGroups: union(defaults.securityRule, rule).source.applicationSecurityGroups // any(sourceApplicationSecurityGroupsById[index])
                sourcePortRange: ((1 == length(rule.source.addressPrefixes)) ? first(rule.source.ports) : null)
                sourcePortRanges: ((1 < length(rule.source.addressPrefixes)) ? rule.source.ports : null)
            }
        }]
    }
    tags: tags
}
