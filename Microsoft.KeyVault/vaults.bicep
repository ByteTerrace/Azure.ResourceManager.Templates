@description('Specifies the location in which the Azure Key Vault resource(s) will be deployed.')
param location string
@maxLength(24)
@minLength(3)
@description('Specifies the name of the Azure SQL Server.')
param name string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
    location: location
    name: name
    properties: {
        accessPolicies: []
        enabledForDeployment: false
        enabledForDiskEncryption: false
        enabledForTemplateDeployment: false
        enablePurgeProtection: true
        enableRbacAuthorization: true
        enableSoftDelete: true
        networkAcls: {
            bypass: 'None'
            defaultAction: 'Deny'
            ipRules: []
            virtualNetworkRules: []
        }
        publicNetworkAccess: 'Disabled'
        sku: {
            family: 'A'
            name: 'premium'
        }
        softDeleteRetentionInDays: 14
        tenantId: tenant().tenantId
    }
}
