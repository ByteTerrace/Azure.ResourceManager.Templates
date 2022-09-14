@description('Specifies the name of the Azure CDN Profile.')
param name string
@description('Specifies the SKU of the Azure CDN Profile.')
param sku object
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure CDN Profile.')
param tags object = {}

resource profile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
    location: 'global'
    name: name
    properties: {}
    sku: sku
    tags: tags
}
