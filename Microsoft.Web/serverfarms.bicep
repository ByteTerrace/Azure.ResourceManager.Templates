@description('Indicates whether the feature that enables applications to scale independently is enabled on the Azure Application Service Plan.')
param isPerSiteScalingEnabled bool = false
@description('Indicates whether the zone redundancy feature is enabled on the Azure Application Service Plan.')
param isZoneRedundancyEnabled bool = true
@description('Specifies the location in which the Azure Application Service Plan resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Service Plan.')
param name string
@description('Specifies the SKU name of the Azure Application Service Plan.')
param sku object
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Application Service Plan.')
param tags object = {}

resource servicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
    location: location
    name: name
    properties: {
        maximumElasticWorkerCount: 1
        perSiteScaling: isPerSiteScalingEnabled
        zoneRedundant: isZoneRedundancyEnabled
    }
    sku: sku
    tags: tags
}
