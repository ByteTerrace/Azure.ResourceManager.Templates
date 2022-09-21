@description('An object that encapsulates the properties of the Azure Application Insights that will be associated with the Azure Machine Learning Services Workspace.')
param applicationInsights object
@description('An object that encapsulates the properties of the Azure Container Registry that will be associated with the Azure Machine Learning Services Workspace.')
param containerRegistry object
@description('An array of compute clusters that will be created with the Azure Machine Learning Services Workspace.')
param computeClusters array = []
@description('An array of environments that will be created with the Azure Machine Learning Services Workspace.')
param environments array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Machine Learning Services Workspace.')
param identity object
@description('Indicates whether high business impact feature is enabled on the Azure Machine Learning Services Workspace.')
param isHighBusinessImpactFeatureEnabled bool = false
@description('Indicates whether the Azure Machine Learning Services Workspace is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('An object that encapsulates the properties of the Azure Key Vault that will be associated with the Azure Machine Learning Services Workspace.')
param keyVault object
@description('Specifies the location in which the Azure Machine Learning Services Workspace resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Machine Learning Services Workspace.')
param name string
@description('Specifies the SKU of the Azure Machine Learning Services Workspace.')
param sku object = {
    name: 'Basic'
}
@description('An object that encapsulates the properties of the Azure Storage Account that will be associated with the Azure Machine Learning Services Workspace.')
param storageAccount object
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Machine Learning Services Workspace.')
param tags object = {}

var userAssignedIdentities = [for managedIdentity in union({
    userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
    subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
    resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource computeClustersCopy 'Microsoft.MachineLearningServices/workspaces/computes@2022-06-01-preview' = [for cluster in computeClusters: {
    location: union({ location: location }, cluster).location
    name: cluster.name
    parent: workspace
    properties: {
        computeType: cluster.type
        description: union({ description: null }, cluster).description
        disableLocalAuth: false
        properties: ('aks' == toLower(cluster.type)) ? null : (('amlcompute' == toLower(cluster.type)) ? {
            enableNodePublicIp: union({ isPublicIpAddressEnabled: false }, cluster).isPublicIpAddressEnabled
            osType: union({ osType: null }, cluster).osType
            scaleSettings: empty(union({ scaleSettings: {} }, cluster)) ? null : {
                maxNodeCount: union({ maximumNodeCount: 1 }, cluster.scaleSettings).maximumNodeCount
                minNodeCount: union({ minimumNodeCount: 0 }, cluster.scaleSettings).minimumNodeCount
            }
            subnet: empty(union({ subnet: {} }, cluster).subnet) ? null: {
                id: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, cluster.subnet).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, cluster.subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', cluster.subnet.virtualNetworkName, cluster.subnet.name)
            }
            vmPriority: union({ virtualMachinePriority: 'Dedicated' }, cluster).virtualMachinePriority
            vmSize: cluster.virtualMachineSize
        } : null)
        resourceId: any(format('/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}', union({
            subscriptionId: subscription().subscriptionId
        }, cluster.resource).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, cluster.resource).resourceGroupName, cluster.resource.type, cluster.resource.name))
    }
    tags: tags
}]
resource environmentsCopy 'Microsoft.MachineLearningServices/workspaces/environments@2022-06-01-preview' = [for environment in environments: {
    name: environment.name
    parent: workspace
    properties: {
        description: union({ description: null }, environment).description
        isArchived: union({ isArchived: false }, environment).isArchived
        properties: environment.properties
        tags: union({ tags: {} }, environment).tags
    }
}]
resource workspace 'Microsoft.MachineLearningServices/workspaces@2022-06-01-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        allowPublicAccessWhenBehindVnet: isPublicNetworkAccessEnabled
        applicationInsights: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, applicationInsights).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, applicationInsights).resourceGroupName, 'Microsoft.Insights/components', applicationInsights.name)
        containerRegistry: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, containerRegistry).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, containerRegistry).resourceGroupName, 'Microsoft.ContainerRegistry/registries', containerRegistry.name)
        friendlyName: name
        hbiWorkspace: isHighBusinessImpactFeatureEnabled
        keyVault: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, keyVault).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, keyVault).resourceGroupName, 'Microsoft.KeyVault/vaults', keyVault.name)
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        storageAccount: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, storageAccount).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccount.name)
    }
    sku: sku
    tags: tags
}
