@description('Specifies the location in which the Azure Managed Identity resource(s) should be deployed.')
param location string
@maxLength(128)
@minLength(3)
@description('Specifies the name of the Azure Managed Identity.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Managed Identity.')
param tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    location: location
    name: name
    tags: tags
}
