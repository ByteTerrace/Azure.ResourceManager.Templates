@description('An object that encapsulates the properties of the backup policy that will be applied to the Azure Cosmos DB Account.')
param backupPolicy object = {
    continuousModeProperties: {
        tier: 'Continuous7Days'
    }
    type: 'Continuous'
}
@description('An array of capabilities that will be set on the Azure Cosmos DB Account.')
param capabilities array = []
@description('An object that encapsulates the properties of the consistency policy that will be applied to the Azure Cosmos DB Account.')
param consistencyPolicy object = {}
@description('An array of cross-origin resource sharing rules that will be assigned to the Azure Cosmos DB Account.')
param corsRules array = []
@description('An array of firewall rules that will be assigned to the Azure Cosmos DB Account.')
param firewallRules array = []
@description('An array of locations that the Azure Cosmos DB Account will be replicated to.')
param geoReplicationLocations array = []
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Cosmos DB Account.')
param identity object = {}
@description('Indicates whether trusted Microsoft services are allowed to access the Azure Cosmos DB Account.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the analytical storage feature is enabled on the Azure Cosmos DB Account.')
param isAnalyticalStorageEnabled bool = false
@description('Indicates whether the automatic failover feature is enabled on the Azure Cosmos DB Account.')
param isAutomaticFailoverEnabled bool = false
@description('Indicates whether access via the Azure Portal is enabled on the Azure Cosmos DB Account.')
param isAzurePortalAccessEnabled bool = true
@description('Indicates whether access via public Azure datacenters is enabled on the Azure Cosmos DB Account.')
param isAzurePublicDatacenterAccessEnabled bool = true
@description('Indicates whether free tier feature is enabled on the Azure Cosmos DB Account.')
param isFreeTierEnabled bool = false
@description('Indicates whether the Azure Cosmos DB Account is capable of writing to multiple locations.')
param isMultipleWriteLocationsEnabled bool = false
@description('Indicates whether the Azure Cosmos DB Account is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether server-less mode is enabled on the Azure Cosmos DB Account.')
param isServerlessModeEnabled bool = true
@description('Specifies the kind of the Azure Cosmos DB Account.')
@allowed([
    'Cassandra'
    'Gremlin'
    'MongoDB'
    'SQL'
    'Table'
])
param kind string = 'SQL'
@description('Specifies the location in which the Azure Cosmos DB Account resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Cosmos DB Account.')
param name string
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Cosmos DB Account.')
param tags object = {}
@description('An array of virtual network rules that will be assigned to the Azure Cosmos DB Account.')
param virtualNetworkRules array = []

var defaultCapabilities = ('Cassandra' == kind) ? cassandraCapabilities : (('Gremlin' == kind) ? gremlinCapabilities : (('MongoDB' == kind) ? mongoDbCapabilities : (('Table' == kind) ? tableCapabilities : [])))
var cassandraCapabilities = union([ { name: 'EnableCassandra' } ], isCapabilitiesEmpty ? serverSideRetryCapabilities : [])
var gremlinCapabilities = [ { name: 'EnableGremlin' } ]
var isCapabilitiesEmpty = empty(capabilities)
var mongoDbCapabilities = [ { name: 'EnableMongo' } ]
var serverSideRetryCapabilities = [ { name: 'DisableRateLimitingResponses' } ]
var serverlessCapabilities = [ { name: 'EnableServerless' } ]
var tableCapabilities = [ { name: 'EnableTable' } ]
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    kind: ('MongoDB' == kind) ? 'MongoDB' : 'GlobalDocumentDB'
    location: location
    name: name
    properties: {
        backupPolicy: backupPolicy
        capabilities: union(defaultCapabilities, (isServerlessModeEnabled ? serverlessCapabilities : []), capabilities)
        consistencyPolicy: {
            defaultConsistencyLevel: union({ defaultConsistencyLevel: 'Session' }, consistencyPolicy).defaultConsistencyLevel
            maxIntervalInSeconds: union({ maximumIntervalInSeconds: 5 }, consistencyPolicy).maximumIntervalInSeconds
            maxStalenessPrefix: union({ maximumStalenessPrefix: 100 }, consistencyPolicy).maximumStalenessPrefix
        }
        cors: [for rule in corsRules: {
            allowedOrigins: rule.allowedOrigins
            allowedHeaders: union({ allowedHeaders: null }, rule).allowedHeaders
            allowedMethods: union({ allowedMethods: null }, rule).allowedMethods
            exposedHeaders: union({ exposedHeaders: null }, rule).exposedHeaders
            maxAgeInSeconds: union({ maximumAgeInSeconds: null }, rule).maximumAgeInSeconds
        }]
        databaseAccountOfferType: 'Standard'
        disableLocalAuth: true
        enableAnalyticalStorage: isAnalyticalStorageEnabled
        enableAutomaticFailover: isAutomaticFailoverEnabled
        enableFreeTier: isFreeTierEnabled
        enableMultipleWriteLocations: isMultipleWriteLocationsEnabled
        ipRules: [for rule in union(isAzurePortalAccessEnabled ? [
            '40.76.54.131'
            '52.169.50.45'
            '52.176.6.30'
            '52.187.184.26'
            '104.42.195.92'
        ] : [], isAzurePublicDatacenterAccessEnabled ? [
            '0.0.0.0'
        ] : [], firewallRules): {
            ipAddressOrRange: rule
        }]
        isVirtualNetworkFilterEnabled: (0 < length(virtualNetworkRules))
        locations: [for (replicationLocation, index) in (empty(geoReplicationLocations) ? [{
            name: location
        }] : geoReplicationLocations): {
            failoverPriority: union({ failoverPriority: index }, replicationLocation).failoverPriority
            isZoneRedundant: union({ isZoneRedundant: false }, replicationLocation).isZoneRedundant
            locationName: replicationLocation.name
        }]
        networkAclBypass: isAllowTrustedMicrosoftServicesEnabled ? 'AzureServices' : 'None'
        publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        virtualNetworkRules: [for rule in virtualNetworkRules: {
            id: resourceId(union({
                subscriptionId: subscription().subscriptionId
            }, rule.subnet).subscriptionId, union({
                resourceGroupName: resourceGroup().name
            }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetwork/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
            ignoreMissingVNetServiceEndpoint: false
        }]
    }
    tags: tags
}
