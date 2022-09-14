@description('An object that encapsulates the properties of the Azure Managed Application Definition that will be associated with the Azure Managed Application.')
param definition object
@description('Specifies the location in which the Azure Managed Application resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Managed Application.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Managed Application.')
param tags object = {}

resource application 'Microsoft.Solutions/applications@2021-07-01' = {
    kind: 'ServiceCatalog'
    location:location
    name: name
    properties: {
        applicationDefinitionId: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, definition).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, definition).resourceGroupName, 'Microsoft.Solutions/applicationDefinitions', definition.name)
        jitAccessPolicy: {
            jitAccessEnabled: false
            jitApprovalMode: 'NotSpecified'
            jitApprovers: null
            maximumJitAccessDuration: null
        }
        managedResourceGroupId: 'string'
        parameters: null
    }
    tags: tags
}
