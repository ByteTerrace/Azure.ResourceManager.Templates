@description('An array of address prefixes, in CIDR notation, that will be assigned to the Azure Virtual Network.')
param addressPrefixes array
@description('An object that encapsulates the DDOS protection plan settings that will be applied to the Azure Virtual Network.')
param ddosProtectionPlan object
@description('Specifies the location in which the Azure Virtual Network resource(s) will be deployed.')
param location string
@maxLength(64)
@minLength(2)
@description('Specifies the name of the Azure Virtual Network.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Virtual Network.')
param tags object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
    location: location
    name: name
    properties: {
        addressSpace: {
            addressPrefixes: addressPrefixes
        }
        ddosProtectionPlan: (empty(ddosProtectionPlan) ? null : {
            id: resourceId(union({
                resourceGroupName: resourceGroup().name
            }, ddosProtectionPlan).resourceGroupName, union({
                subscriptionId: subscription().subscriptionId
            }, ddosProtectionPlan).subscriptionId, 'Microsoft.Network/ddosProtectionPlans', ddosProtectionPlan.name)
        })
    }
    tags: tags
}
