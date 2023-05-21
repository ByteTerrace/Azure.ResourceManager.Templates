param location string = resourceGroup().location
param name string
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  location: location
  name: name
  tags: tags
}
