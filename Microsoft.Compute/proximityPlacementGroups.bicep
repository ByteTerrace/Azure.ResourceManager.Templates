@description('An array of availability zones that the Azure Proximity Placement Group will be deployed within.')
param availabilityZones array = []
@description('Specifies the location in which the Azure Proximity Placement Group resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Proximity Placement Group.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Proximity Placement Group.')
param tags object = {}

var zones = [for zone in availabilityZones: string(zone)]

resource proximityPlacementGroup 'Microsoft.Compute/proximityPlacementGroups@2022-03-01' = {
    location: location
    name: name
    properties: {
        proximityPlacementGroupType: 'Standard'
    }
    tags: tags
    zones: zones
}
