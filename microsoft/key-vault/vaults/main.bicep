param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var firewallRules = (properties.?firewallRules ?? [])
var isPublicNetworkAccessEnabled = (properties.?isPublicNetworkAccessEnabled ?? false)
var resourceGroupName = resourceGroup().name
var roleAssignmentsTransform = map((properties.?roleAssignments ?? []), assignment => {
  description: (assignment.?description ?? 'Created via automation.')
  principalId: assignment.principalId
  resource: (empty(assignment.resource) ? null : {
    apiVersion: assignment.resource.apiVersion
    id: '/subscriptions/${(assignment.resource.?subscriptionId ?? subscriptionId)}/resourceGroups/${(assignment.resource.?resourceGroupName ?? resourceGroupName)}/providers/${assignment.resource.type}/${assignment.resource.path}'
    type: assignment.resource.type
  })
  roleDefinitionId: assignment.roleDefinitionId
})
var subscriptionId = subscription().subscriptionId
var virtualNetworkRules = (properties.?virtualNetworkRules ?? [])

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(vault.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
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
