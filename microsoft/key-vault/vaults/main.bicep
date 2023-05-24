param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var firewallRules = (properties.?firewallRules ?? [])
var isPublicNetworkAccessEnabled = (properties.?isPublicNetworkAccessEnabled ?? false)
var resourceGroupName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var virtualNetworkRules = (properties.?virtualNetworkRules ?? [])

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
}): {
  name: sys.guid(vault.id, assignment.roleDefinitionId, assignment.principalId)
  properties: {
    description: assignment.description
    principalId: assignment.principalId
    roleDefinitionId: any(assignment.roleDefinitionId)
  }
  scope: vault
}]
resource subnetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for rule in virtualNetworkRules: {
  name: '${rule.subnet.virtualNetworkName}/${rule.subnet.name}'
  scope: resourceGroup((rule.subnet.?subscriptionId ?? subscriptionId), (rule.subnet.?resourceGroupName ?? resourceGroupName))
}]
resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: name
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: (properties.?isVirtualMachineDeploymentEnabled ?? false)
    enabledForDiskEncryption: (properties.?isDiskEncryptionEnabled ?? false)
    enabledForTemplateDeployment: (properties.?isTemplateDeploymentEnabled ?? false)
    enablePurgeProtection: (properties.?isPurgeProtectionEnabled ?? true)
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: (isPublicNetworkAccessEnabled ? 'AzureServices' : 'None')
      defaultAction: ((isPublicNetworkAccessEnabled && empty(firewallRules) && empty(virtualNetworkRules)) ? 'Allow' : 'Deny')
      ipRules: [for rule in firewallRules: { value: rule }]
      virtualNetworkRules: [for (rule, index) in virtualNetworkRules: {
        id: subnetsRef[index].id
        ignoreMissingVnetServiceEndpoint: false
      }]
    }
    publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled')
    sku: union({ family: 'A' }, properties.sku)
    softDeleteRetentionInDays: (properties.?softDeleteRetentionInDays ?? null)
    tenantId: (properties.?tenantId ?? tenant().tenantId)
  }
  tags: tags
}
