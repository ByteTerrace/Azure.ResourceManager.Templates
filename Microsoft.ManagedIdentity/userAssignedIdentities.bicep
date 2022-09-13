@description('Specifies the location in which the Azure User-Assigned Managed Identity resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure User-Assigned Managed Identity.')
param name string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
    location: location
    name: name
}
