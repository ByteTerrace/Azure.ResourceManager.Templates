@description('Specifies the mode of the Azure Resource Deployment.')
param mode string = 'Incremental'
@description('Specifies the name of the Azure Resource Deployment.')
param name string
@description('An object that encapsulates the parameters that will be passed to the Azure Resource Deployment.')
param parameters object = {}
@description('Specifies the resource group name that the Azure Resource Deployment will update.')
param resourceGroupName string
@description('Specifies the subscription id of the resource group that the Azure Resource Deployment will update.')
param subscriptionId string
@description('An object that encapsulates the properties of the external template that will be imported by the Azure Resource Deployment.')
param templateLink object

resource deployment 'Microsoft.Resources/deployments@2021-04-01' = {
    name: name
    properties: {
        expressionEvaluationOptions: {
            scope: 'NotSpecified'
        }
        mode: mode
        parameters: [for parameter in items(parameters): {
            '${parameter.key}': {
                value: parameter.value
            }
        }]
        templateLink: templateLink
    }
    resourceGroup: resourceGroupName
    subscriptionId: subscriptionId
}
