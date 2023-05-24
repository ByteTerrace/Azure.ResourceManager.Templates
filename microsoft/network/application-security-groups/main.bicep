param location string = resourceGroup().location
param name string
param tags object = {}

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2022-11-01' = {
  location: location
  name: name
  tags: tags
}
