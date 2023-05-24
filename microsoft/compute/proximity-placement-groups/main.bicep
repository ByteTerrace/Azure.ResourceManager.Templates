param location string = resourceGroup().location
param name string
param tags object = {}

resource proximityPlacementGroup 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' = {
  location: location
  name: name
  tags: tags
}
