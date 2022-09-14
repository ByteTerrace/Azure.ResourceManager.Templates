@sys.description('An array of role assignments that will be applied to the resource(s) deployed by the Azure Managed Application Definition.')
param authorizations array = []
@sys.description('Specifies the description of the Azure Managed Application Definition.')
param description string = ''
@sys.description('Specifies the display name of the Azure Managed Application Definition.')
param displayName string = ''
@sys.description('Indicates whether the Azure Managed Application Definition is enabled.')
param isEnabled bool = true
@sys.description('Specifies the location in which the Azure Managed Application Definition resource(s) will be deployed.')
param location string = resourceGroup().location
@sys.description('Specifies the lock level of the Azure Managed Application Definition.')
param lockLevel string = 'ReadOnly'
@sys.description('Specifies the name of the Azure Managed Application Definition.')
param name string
@sys.description('Specifies the URI of the Azure Managed Application Definition package file.')
param packageFileUri string
@sys.description('An object that encapsulates the properties of the Azure Storage Account that will be associated with the Azure Managed Application Definition.')
param storageAccount object = {}
@sys.description('Specifies the set of tag key-value pairs that will be assigned to the Azure Managed Application Definition.')
param tags object = {}

resource applicationDefinition 'Microsoft.Solutions/applicationDefinitions@2021-07-01' = {
    location: location
    name: name
    properties: {
        authorizations: authorizations
        description: empty(description) ? null : description
        displayName: empty(displayName) ? name : displayName
        isEnabled: isEnabled
        lockLevel: lockLevel
        packageFileUri: packageFileUri
        storageAccountId: empty(storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, storageAccount).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccount.name)
    }
    tags: tags
}
