@description('Specifies the name of the Azure CDN Profile.')
param name string
@description('Specifies the SKU name of the Azure CDN Profile.')
param skuName string

resource profile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
    location: 'global'
    name: name
    sku: {
        name: skuName
    }
    properties: {}
}
