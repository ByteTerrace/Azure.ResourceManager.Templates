@description('Specifies the location in which the Azure Availability Set resource(s) will be deployed.')
param location string
@description('Specifies the name of the Azure Availability Set.')
param name string
@description('Specifies the number of fault domains that the Azure Availability Set will support.')
param numberOfFaultDomains int
@description('Specifies the number of update domains that the Azure Availability Set will support.')
param numberOfUpdateDomains int
@description('An object that encapsulates the properties of the Azure Proximity Placement Group that the Azure Availability Set will be deployed within.')
param proximityPlacementGroup object
@description('Specifies the SKU name of the Azure Availability Set.')
param skuName string

resource availabilitySet 'Microsoft.Compute/availabilitySets@2022-03-01' = {
    location: location
    name: name
    properties: {
        platformFaultDomainCount: numberOfFaultDomains
        platformUpdateDomainCount: numberOfUpdateDomains
        proximityPlacementGroup: empty(proximityPlacementGroup) ? null : {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, proximityPlacementGroup).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, proximityPlacementGroup).resourceGroupName, 'Microsoft.Compute/proximityPlacementGroups', proximityPlacementGroup.name)
        }
    }
    sku: {
        name: skuName
    }
}
