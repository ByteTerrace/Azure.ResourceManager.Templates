param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var isProximityPlacementGroupIsNotEmpty = !empty(properties.?proximityPlacementGroup ?? {})
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-03-01' = {
  location: location
  name: name
  properties: {
    platformFaultDomainCount: properties.faultDomainCount
    platformUpdateDomainCount: properties.updateDomainCount
    proximityPlacementGroup: (isProximityPlacementGroupIsNotEmpty ? { id: proximityPlacementGroup.id } : null)
  }
  tags: tags
}
resource proximityPlacementGroup 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' existing = if (isProximityPlacementGroupIsNotEmpty) {
  name: properties.proximityPlacementGroup.name
  scope: resourceGroup((properties.proximityPlacementGroup.?subscriptionId ?? subscriptionId), (properties.proximityPlacementGroup.?resourceGroupName ?? resourceGroupName))
}
