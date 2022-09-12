@description('An array of firewall rules that will be assigned to the Azure Key Vault.')
param firewallRules array = []
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Key Vault.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the Azure Key Vault is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the purge protection feature is enabled on the Azure Key Vault.')
param isPurgeProtectionEnabled bool = true
@description('Indicates whether the role-based access control feature is enabled on the Azure Key Vault.')
param isRbacAuthorizationEnabled bool = true
@description('Indicates whether Azure Resource Manager is permitted to access secrets from the Azure Key Vault.')
param isTemplateDeploymentEnabled bool = false
@description('Specifies the location in which the Azure Key Vault resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Key Vault.')
param name string
@description('Specifies the SKU name of the Azure Key Vault.')
param skuName string = 'premium'
@description('Specifies the Azure Active Directory tenant GUID that the Azure Key Vault will be associated with.')
param tenantId string = tenant().tenantId
@description('An array of virtual network rules that will be assigned to the Azure Key Vault.')
param virtualNetworkRules array = []

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
    location: location
    name: name
    properties: {
        accessPolicies: []
        enabledForDeployment: false
        enabledForDiskEncryption: false
        enabledForTemplateDeployment: isTemplateDeploymentEnabled
        enablePurgeProtection: isPurgeProtectionEnabled
        enableRbacAuthorization: isRbacAuthorizationEnabled
        enableSoftDelete: true
        networkAcls: {
            bypass: isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None'
            defaultAction: (isPublicNetworkAccessEnabled && (empty(firewallRules) || empty(virtualNetworkRules))) ? 'Allow' : 'Deny'
            ipRules: [for rule in firewallRules: {
                value: rule
            }]
            virtualNetworkRules: [for rule in virtualNetworkRules: {
                id: resourceId(union({
                    subscriptionId: subscription().subscriptionId
                }, rule.subnet).subscriptionId, union({
                    resourceGroupName: resourceGroup().name
                }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetwork/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
                ignoreMissingVnetServiceEndpoint: false
            }]
        }
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        sku: {
            family: 'A'
            name: skuName
        }
        softDeleteRetentionInDays: 14
        tenantId: tenantId
    }
}
