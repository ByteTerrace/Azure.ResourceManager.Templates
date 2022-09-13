@description('Indicates whether the zone redundancy feature is enabled on the Azure Application Service Plan.')
param isZoneRedundancyEnabled bool = true
@description('Specifies the location in which the Azure Application Service Plan resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Application Service Plan.')
param name string
@description('Specifies the SKU name of the Azure Application Service Plan.')
param sku object

resource servicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
    location: location
    name: name
    properties: {
        maximumElasticWorkerCount: 1
        perSiteScaling: false
        targetWorkerCount: 0
        zoneRedundant: isZoneRedundancyEnabled
    }
    sku: sku
}
