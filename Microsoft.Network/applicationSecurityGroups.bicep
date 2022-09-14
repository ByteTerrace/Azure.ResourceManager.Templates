@description('Specifies the location in which the Azure Application Security Group resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Security Group.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Application Security Group.')
param tags object = {}

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2022-01-01' = {
    location: location
    name: name
    properties: {}
    tags: tags
}
