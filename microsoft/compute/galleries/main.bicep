param location string = resourceGroup().location
param name string
@secure()
param properties object = {}
param tags object = {}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  location: location
  name: name
  properties: {
    description: (properties.?description ?? null)
  }
  tags: tags
}
