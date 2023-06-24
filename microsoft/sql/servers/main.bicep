param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

var administrator = (properties.?administrator ?? {})
var databases = items(properties.?databases ?? {})
var elasticPools = items(properties.?elasticPools ?? {})
var identity = (properties.?identity ?? {})
var isAllowTrustedMicrosoftServicesEnabled = (properties.?isAllowTrustedMicrosoftServicesEnabled ?? false)
var isActiveDirectoryAuthenticationEnabled = contains(administrator, 'activeDirectoryPrincipal')
var isPublicNetworkAccessEnabled = (properties.?isPublicNetworkAccessEnabled ?? false)
var isRestrictOutboundNetworkAccessEnabled = (properties.?isRestrictOutboundNetworkAccessEnabled ?? false)
var isSqlAuthenticationEnabled = contains(administrator, 'sqlLogin')
var isUserAssignedIdentitiesNotEmpty = !empty(userAssignedIdentities)
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
var userAssignedIdentities = items(identity.?userAssignedIdentities ?? {})
var userAssignedIdentitiesWithResourceId = [for (identity, index) in userAssignedIdentities: {
  index: index
  isPrimary: (identity.value.?isPrimary ?? (1 == length(userAssignedIdentities)))
  resourceId: userAssignedIdentitiesRef[index].id
}]
var virtualNetworkRules = (properties.?virtualNetworkRules ?? [])

resource server 'Microsoft.Sql/servers@2021-11-01' = {
  identity: {
    type: (identity.?type ?? (isUserAssignedIdentitiesNotEmpty ? 'UserAssigned' : 'None'))
    userAssignedIdentities: (isUserAssignedIdentitiesNotEmpty? toObject(userAssignedIdentitiesWithResourceId, identity => identity.resourceId, identity => {}) : null)
  }
  location: location
  name: name
  properties: {
    administratorLogin: (isSqlAuthenticationEnabled ? administrator.sqlLogin.name : null)
    administratorLoginPassword: (isSqlAuthenticationEnabled ? administrator.sqlLogin.password : null)
    administrators: (isActiveDirectoryAuthenticationEnabled ? {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: !isSqlAuthenticationEnabled
      login: administrator.activeDirectoryPrincipal.name
      principalType: (administrator.?activeDirectoryPrincipal.?type ?? null)
      sid: administrator.activeDirectoryPrincipal.id
      tenantId: (administrator.?activeDirectoryPrincipal.?tenantId ?? tenant().tenantId)
    } : null)
    minimalTlsVersion: '1.2'
    primaryUserAssignedIdentityId: (isUserAssignedIdentitiesNotEmpty ? any(first(filter(userAssignedIdentitiesWithResourceId, identity => identity.isPrimary))).resourceId : null)
    publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled')
    restrictOutboundNetworkAccess: (isRestrictOutboundNetworkAccessEnabled ? 'Enabled' : 'Disabled')
    version: '12.0'
  }
  tags: tags
}
resource serverDatabases 'Microsoft.Sql/servers/databases@2021-11-01' = [for database in map(databases, database => {
  catalogCollation: (database.value.?catalogCollation ?? null)
  defaultCollation: (database.value.?defaultCollation ?? null)
  elasticPoolName: (database.value.?elasticPoolName ?? null)
  isAzureHybridBenefitEnabled: (database.value.?isAzureHybridBenefitEnabled ?? false)
  isElasticPoolHosted: contains(database.value, 'elasticPoolName')
  isLedgerEnabled: (database.value.?isLedgerEnabled ?? null)
  isZoneRedundancyEnabled: (database.value.?isZoneRedundancyEnabled ?? null)
  maximumSizeInBytes: (database.value.?maximumSizeInBytes ?? null)
  name: database.key
}): {
  dependsOn: [ serverElasticPools ]
  location: location
  name: database.name
  parent: server
  properties: {
    catalogCollation: database.catalogCollation
    collation: database.defaultCollation
    createMode: 'Default'
    elasticPoolId: (database.isElasticPoolHosted ? resourceId('Microsoft.Sql/servers/elasticPools', name, database.elasticPoolName) : null)
    isLedgerOn: database.isLedgerEnabled
    licenseType: (database.isElasticPoolHosted ? null : (database.isAzureHybridBenefitEnabled ? 'BasePrice' : 'LicenseIncluded'))
    maxSizeBytes: database.maximumSizeInBytes
    zoneRedundant: (database.isElasticPoolHosted ? null : database.isZoneRedundancyEnabled)
  }
}]
resource serverElasticPools 'Microsoft.Sql/servers/elasticPools@2021-11-01' = [for pool in elasticPools: {
  location: location
  name: pool.key
  parent: server
  properties: {
    licenseType: ((pool.value.?isAzureHybridBenefitEnabled ?? false) ? 'BasePrice' : 'LicenseIncluded')
    maxSizeBytes: (pool.value.?maximumSizeInBytes ?? null)
    perDatabaseSettings: {
      maxCapacity: (pool.value.?perDatabaseSettings.?maximumCapacity ?? int(last(split(pool.value.sku.name, '_'))))
      minCapacity: (pool.value.?perDatabaseSettings.?minimumCapacity ?? 0)
    }
    zoneRedundant: (pool.value.?isZoneRedundancyEnabled ?? null)
  }
  sku: pool.value.sku
}]
resource serverFirewallRules 'Microsoft.Sql/servers/firewallRules@2021-11-01' = [for rule in map(union(map((properties.?firewallRules ?? []), rule => {
  cidr: rule
  name: replace('${rule}${(contains(rule, '/') ? '': '/32')}', '/', '_')
}), (isAllowTrustedMicrosoftServicesEnabled ? [{
  cidr: '0.0.0.0/32'
  name: 'AllowAllWindowsAzureIps'
}] : [])), rule => {
  cidr: parseCidr(rule.cidr)
  name: rule.name
}): if (isPublicNetworkAccessEnabled) {
  name: rule.name
  parent: server
  properties: {
    endIpAddress: rule.cidr.lastUsable
    startIpAddress: rule.cidr.firstUsable
  }
}]
resource serverRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignmentsTransform: {
  name: sys.guid(server.id, assignment.roleDefinitionId, (empty(assignment.principalId) ? any(assignment.resource).id : assignment.principalId))
  properties: {
    description: assignment.description
    principalId: (empty(assignment.principalId) ? reference(any(assignment.resource).id, any(assignment.resource).apiVersion, 'Full')[(('microsoft.managedidentity/userassignedidentities' == toLower(any(assignment.resource).type)) ? 'properties' : 'identity')].principalId : assignment.principalId)
    roleDefinitionId: assignment.roleDefinitionId
  }
  scope: server
}]
resource serverVirtualNetworkRules 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01' = [for (rule, index) in virtualNetworkRules: {
  name: guid(virtualNetworkSubetsRef[index].id)
  parent: server
  properties: {
    ignoreMissingVnetServiceEndpoint: false
    virtualNetworkSubnetId: virtualNetworkSubetsRef[index].id
  }
}]
resource userAssignedIdentitiesRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [for identity in userAssignedIdentities: {
  name: identity.key
  scope: resourceGroup((identity.value.?subscriptionId ?? subscriptionId), (identity.value.?resourceGroupName ?? resourceGroupName))
}]
resource virtualNetworkSubetsRef 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = [for rule in virtualNetworkRules: {
  name: '${rule.subnet.virtualNetworkName}/${rule.subnet.name}'
  scope: resourceGroup((rule.subnet.?subscriptionId ?? subscriptionId), (rule.subnet.?resourceGroupName ?? resourceGroupName))
}]
