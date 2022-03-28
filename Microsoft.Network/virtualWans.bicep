@description('Indicates whether branch-to-branch traffic is enabled on the Azure Virtual WAN.')
param isBranchToBranchTrafficEnabled bool
@description('Indicates whether VPN encryption is enabled on the Azure Virtual WAN.')
param isVirtualPrivateNetworkEncryptionEnabled bool
@description('Specifies the location in which the Azure Virtual WAN resource(s) will be deployed.')
param location string
@maxLength(80)
@minLength(1)
@description('Specifies the name of the Azure Virtual WAN.')
param name string
@allowed([
    'Basic'
    'Standard'
])
@description('Specifies the kind of the Azure Virtual WAN.')
param skuName string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Virtual WAN.')
param tags object

resource virtualWan 'Microsoft.Network/virtualWans@2021-05-01' = if(true) {
    location: location
    name: name
    properties: {
        allowBranchToBranchTraffic: isBranchToBranchTrafficEnabled
        disableVpnEncryption: !isVirtualPrivateNetworkEncryptionEnabled
        type: skuName
    }
    tags: tags
}
