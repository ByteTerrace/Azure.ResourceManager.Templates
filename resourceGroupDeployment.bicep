param location string
param projectName string
param overrides object = {
    excludedTypes: []
    includedTypes: []
}
param resourceDefinitions object = {}

// variables
var excludedTypes = [for type in overrides.excludedTypes: toLower(type)]
var includedTypes = [for type in empty(overrides.includedTypes) ? [
    'microsoft.api-management/service'
    'microsoft.app-configuration/configuration-stores'
    'microsoft.authorization/role-assignments'
    'microsoft.cache/redis'
    'microsoft.cdn/profiles'
    'microsoft.compute/availability-sets'
    'microsoft.compute/disk-encryption-sets'
    'microsoft.compute/proximity-placement-groups'
    'microsoft.compute/virtual-machines'
    'microsoft.container-registry/registries'
    'microsoft.container-service/managed-clusters'
    'microsoft.document-db/database-accounts'
    'microsoft.insights/components'
    'microsoft.key-vault/vaults'
    'microsoft.machine-learning-services/workspaces'
    'microsoft.managed-identity/user-assigned-identities'
    'microsoft.network/application-gateways'
    'microsoft.network/application-security-groups'
    'microsoft.network/dns-zones'
    'microsoft.network/nat-gateways'
    'microsoft.network/network-interfaces'
    'microsoft.network/network-security-groups'
    'microsoft.network/private-dns-zones'
    'microsoft.network/private-endpoints'
    'microsoft.network/public-ip-addresses'
    'microsoft.network/public-ip-prefixes'
    'microsoft.network/route-tables'
    'microsoft.network/virtual-network-gateways'
    'microsoft.network/virtual-networks'
    'microsoft.operational-insights/workspaces'
    'microsoft.resources/deployments'
    'microsoft.service-bus/namespaces'
    'microsoft.signalr-service/signalr'
    'microsoft.solutions/application-definitions'
    'microsoft.solutions/applications'
    'microsoft.sql/servers'
    'microsoft.storage/storage-accounts'
    'microsoft.web/hosting-environments'
    'microsoft.web/server-farms'
    'microsoft.web/sites'
] : overrides.includedTypes: toLower(type)]

// resource definitions
var apiManagementServices = union({ apiManagementServices: []}, resourceDefinitions).apiManagementServices
var applicationConfigurationStores = union({ applicationConfigurationStores: []}, resourceDefinitions).applicationConfigurationStores
var applicationGateways = union({ applicationGateways: []}, resourceDefinitions).applicationGateways
var applicationInsights = union({ applicationInsights: []}, resourceDefinitions).applicationInsights
var applicationSecurityGroups = union({ applicationSecurityGroups: []}, resourceDefinitions).applicationSecurityGroups
var applicationServiceEnvironments = union({ applicationServiceEnvironments: []}, resourceDefinitions).applicationServiceEnvironments
var applicationServicePlans = union({ applicationServicePlans: []}, resourceDefinitions).applicationServicePlans
var availabilitySets = union({ availabilitySets: []}, resourceDefinitions).availabilitySets
var cdnProfiles = union({ cdnProfiles: []}, resourceDefinitions).cdnProfiles
var containerRegistries = union({ containerRegistries: []}, resourceDefinitions).containerRegistries
var cosmosDbAccounts = union({ cosmosDbAccounts: []}, resourceDefinitions).cosmosDbAccounts
var deployments = union({ deployments: []}, resourceDefinitions).deployments
var diskEncryptionSets = union({ diskEncryptionSets: []}, resourceDefinitions).diskEncryptionSets
var keyVaults = union({ keyVaults: []}, resourceDefinitions).keyVaults
var kubernetesServicesClusters = union({ kubernetesServicesClusters: []}, resourceDefinitions).kubernetesServicesClusters
var logAnalyticsWorkspaces = union({ logAnalyticsWorkspaces: []}, resourceDefinitions).logAnalyticsWorkspaces
var machineLearningWorkspaces = union({ machineLearningWorkspaces: []}, resourceDefinitions).machineLearningWorkspaces
var managedApplicationDefinitions = union({ managedApplicationDefinitions: []}, resourceDefinitions).managedApplicationDefinitions
var managedApplications = union({ managedApplications: []}, resourceDefinitions).managedApplications
var natGateways = union({ natGateways: []}, resourceDefinitions).natGateways
var networkInterfaces = union({ networkInterfaces: []}, resourceDefinitions).networkInterfaces
var networkSecurityGroups = union({ networkSecurityGroups: []}, resourceDefinitions).networkSecurityGroups
var privateDnsZones = union({ privateDnsZones: []}, resourceDefinitions).privateDnsZones
var privateEndpoints = union({ privateEndpoints: []}, resourceDefinitions).privateEndpoints
var proximityPlacementGroups = union({ proximityPlacementGroups: []}, resourceDefinitions).proximityPlacementGroups
var publicDnsZones = union({ publicDnsZones: []}, resourceDefinitions).publicDnsZones
var publicIpAddresses = union({ publicIpAddresses: []}, resourceDefinitions).publicIpAddresses
var publicIpPrefixes = union({ publicIpPrefixes: []}, resourceDefinitions).publicIpPrefixes
var redisCaches = union({ redisCaches: []}, resourceDefinitions).redisCaches
var roleAssignments = union({ roleAssignments: []}, resourceDefinitions).roleAssignments
var routeTables = union({ routeTables: []}, resourceDefinitions).routeTables
var serviceBusNamespaces = union({ serviceBusNamespaces: []}, resourceDefinitions).serviceBusNamespaces
var signalrServices = union({ signalrServices: []}, resourceDefinitions).signalrServices
var sqlServers = union({ sqlServers: []}, resourceDefinitions).sqlServers
var storageAccounts = union({ storageAccounts: []}, resourceDefinitions).storageAccounts
var userAssignedIdentities = union({ userAssignedIdentities: []}, resourceDefinitions).userAssignedIdentities
var virtualMachines = union({ virtualMachines: []}, resourceDefinitions).virtualMachines
var virtualNetworkGateways = union({ virtualNetworkGateways: []}, resourceDefinitions).virtualNetworkGateways
var virtualNetworks = union({ virtualNetworks: []}, resourceDefinitions).virtualNetworks
var webApplications = union({ webApplications: []}, resourceDefinitions).webApplications

// module imports
module apiManagementServicesCopy 'br/main:microsoft.api-management/service:1.0.0' = [for (service, index) in apiManagementServices: if (contains(includedTypes, 'microsoft.api-management/service') && !contains(excludedTypes, 'microsoft.api-management/service')) {
    dependsOn: [
        keyVaultsCopy
        publicIpAddressesCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-apim-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, service).availabilityZones
        hostnameConfigurations: union({ hostnameConfigurations: [] }, service).hostnameConfigurations
        identity: union({ identity: {} }, service).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, service).isPublicNetworkAccessEnabled
        location: union({ location: location }, service).location
        name: union({ name: '${projectName}-apim-${padLeft(index, 5, '0')}' }, service).name
        publicIpAddress: union({ publicIpAddress: {} }, service).publicIpAddress
        publisher: service.publisher
        sku: union({ sku: {
            capacity: 1
            name: 'Standard'
        } }, service).sku
        subnet: union({ subnet: {} }, service).subnet
        tags: union({ tags: {} }, service).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, service).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, service).resourceGroupName)
}]
module applicationConfigurationStoresCopy 'br/main:microsoft.app-configuration/configuration-stores:1.0.0' = [for (store, index) in applicationConfigurationStores: if (contains(includedTypes, 'microsoft.app-configuration/configuration-stores') && !contains(excludedTypes, 'microsoft.app-configuration/configuration-stores')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-acs-${string(index)}'
    params: {
        identity: union({ identity: {} }, store).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, store).isPublicNetworkAccessEnabled
        isPurgeProtectionEnabled: union({ isPurgeProtectionEnabled: true }, store).isPurgeProtectionEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, store).isSharedKeyAccessEnabled
        location: union({ location: location }, store).location
        name: union({ name: '${projectName}-acs-${padLeft(index, 5, '0')}' }, store).name
        settings: union({ settings: {} }, store).settings
        sku: union({ sku: { name: 'Premium' } }, store).sku
        tags: union({ tags: {} }, store).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, store).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, store).resourceGroupName)
}]
module applicationGatewaysCopy 'br/main:microsoft.network/application-gateways:1.0.0' = [for (gateway, index) in applicationGateways: if (contains(includedTypes, 'microsoft.network/application-gateways') && !contains(excludedTypes, 'microsoft.network/application-gateways')) {
    dependsOn: [
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-ag-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, gateway).availabilityZones
        backendAddressPools: gateway.backendAddressPools
        backendHttpSettings: gateway.backendHttpSettings
        frontEnd: gateway.frontEnd
        httpListeners: gateway.httpListeners
        identity: union({ identity: {} }, gateway).identity
        location: union({ location: location }, gateway).location
        name: union({ name: '${projectName}-ag-${padLeft(index, 5, '0')}' }, gateway).name
        routingRules: gateway.routingRules
        sku: union({ sku: {
            capacity: 1
            name: 'Standard_v2'
            tier: 'Standard_v2'
        } }, gateway).sku
        subnet: gateway.subnet
        tags: union({ tags: {} }, gateway).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module applicationInsightsCopy 'br/main:microsoft.insights/components:1.0.0' = [for (component, index) in applicationInsights: if (contains(includedTypes, 'microsoft.insights/components') && !contains(excludedTypes, 'microsoft.insights/components')) {
    dependsOn: [
        logAnalyticsWorkspacesCopy
    ]
    name: '${deployment().name}-ai-${string(index)}'
    params: {
        location: union({ location: location }, component).location
        logAnalyticsWorkspace: component.logAnalyticsWorkspace
        name: union({ name: '${projectName}-ai-${padLeft(index, 5, '0')}' }, component).name
        tags: union({ tags: {} }, component).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, component).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, component).resourceGroupName)
}]
module applicationSecurityGroupsCopy 'br/main:microsoft.network/application-security-groups:1.0.0' = [for (group, index) in applicationSecurityGroups: if (contains(includedTypes, 'microsoft.network/application-security-groups') && !contains(excludedTypes, 'microsoft.network/application-security-groups')) {
    name: '${deployment().name}-asg-${string(index)}'
    params: {
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-asg-${padLeft(index, 5, '0')}' }, group).name
        tags: union({ tags: {} }, group).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module applicationServiceEnvironmentsCopy 'br/main:microsoft.web/hosting-environments:1.0.0' = [for (environment, index) in applicationServiceEnvironments: if (contains(includedTypes, 'microsoft.web/hosting-environments') && !contains(excludedTypes, 'microsoft.web/hosting-environments')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-ase-${string(index)}'
    params: {
        isDedicatedHostGroup: union({ isDedicatedHostGroup: false }, environment).isDedicatedHostGroup
        isInternalEncryptionEnabled: union({ isInternalEncryptionEnabled: false }, environment).isInternalEncryptionEnabled
        isMinimalSslCipherSuiteConfigurationEnabled: union({ isMinimalSslCipherSuiteConfigurationEnabled: true }, environment).isMinimalSslCipherSuiteConfigurationEnabled
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, environment).isZoneRedundancyEnabled
        kind: union({ kind: 'ASEV3' }, environment).kind
        location: union({ location: location }, environment).location
        name: union({ name: '${projectName}-ase-${padLeft(index, 5, '0')}' }, environment).name
        subnet: environment.subnet
        tags: union({ tags: {} }, environment).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, environment).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, environment).resourceGroupName)
}]
module applicationServicePlansCopy 'br/main:microsoft.web/server-farms:1.0.0' = [for (plan, index) in applicationServicePlans: if (contains(includedTypes, 'microsoft.web/server-farms') && !contains(excludedTypes, 'microsoft.web/server-farms')) {
    dependsOn: [
        applicationServiceEnvironmentsCopy
    ]
    name: '${deployment().name}-asp-${string(index)}'
    params: {
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, plan).isZoneRedundancyEnabled
        location: union({ location: location }, plan).location
        name: union({ name: '${projectName}-asp-${padLeft(index, 5, '0')}' }, plan).name
        sku: plan.sku
        tags: union({ tags: {} }, plan).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, plan).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, plan).resourceGroupName)
}]
module availabilitySetsCopy 'br/main:microsoft.compute/availability-sets:1.0.0' = [for (set, index) in availabilitySets: if (contains(includedTypes, 'microsoft.compute/availability-sets') && !contains(excludedTypes, 'microsoft.compute/availability-sets')) {
    dependsOn: [
        proximityPlacementGroupsCopy
    ]
    name: '${deployment().name}-as-${string(index)}'
    params: {
        location: union({ location: location }, set).location
        name: union({ name: '${projectName}-as-${padLeft(index, 5, '0')}' }, set).name
        numberOfFaultDomains: set.numberOfFaultDomains
        numberOfUpdateDomains: set.numberOfUpdateDomains
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, set).proximityPlacementGroup
        sku: set.sku
        tags: union({ tags: {} }, set).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, set).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, set).resourceGroupName)
}]
module cdnProfilesCopy 'br/main:microsoft.cdn/profiles:1.0.0' = [for (profile, index) in cdnProfiles: if (contains(includedTypes, 'microsoft.cdn/profiles') && !contains(excludedTypes, 'microsoft.cdn/profiles')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
    ]
    name: '${deployment().name}-cdn-${string(index)}'
    params: {
        name: union({ name: '${projectName}-cdn-${padLeft(index, 5, '0')}' }, profile).name
        sku: profile.sku
        tags: union({ tags: {} }, profile).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, profile).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, profile).resourceGroupName)
}]
module containerRegistriesCopy 'br/main:microsoft.container-registry/registries:1.0.0' = [for (registry, index) in containerRegistries: if (contains(includedTypes, 'microsoft.container-registry/registries') && !contains(excludedTypes, 'microsoft.container-registry/registries')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-cr-${string(index)}'
    params: {
        firewallRules: union({ firewallRules: [] }, registry).firewallRules
        identity: union({ identity: {} }, registry).identity
        isAdministratorAccountEnabled: union({ isAdministratorAccountEnabled: false }, registry).isAdministratorAccountEnabled
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, registry).isAllowTrustedMicrosoftServicesEnabled
        isAnonymousPullEnabled: union({ isAnonymousPullEnabled: false }, registry).isAnonymousPullEnabled
        isDedicatedDataEndpointEnabled: union({ isDedicatedDataEndpointEnabled: false }, registry).isDedicatedDataEndpointEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, registry).isPublicNetworkAccessEnabled
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, registry).isZoneRedundancyEnabled
        location: union({ location: location }, registry).location
        name: union({ name: '${projectName}cr${padLeft(index, 5, '0')}'}, registry).name
        sku: union({ sku: { name: 'Premium' } }, registry).sku
        tags: union({ tags: {} }, registry).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, registry).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, registry).resourceGroupName)
}]
module cosmosDbAccountsCopy 'br/main:microsoft.document-db/database-accounts:1.0.0' = [for (account, index) in cosmosDbAccounts: if (contains(includedTypes, 'microsoft.document-db/database-accounts') && !contains(excludedTypes, 'microsoft.document-db/database-accounts')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-cdb-${string(index)}'
    params: {
        backupPolicy: union({ backupPolicy: {
            continuousModeProperties: {
                tier: 'Continuous7Days'
            }
            type: 'Continuous'
        } }, account).backupPolicy
        capabilities: union({ capabilities: [] }, account).capabilities
        consistencyPolicy: union({ consistencyPolicy: {} }, account).consistencyPolicy
        corsRules: union({ corsRules: [] }, account).corsRules
        firewallRules: union({ firewallRules: [] }, account).firewallRules
        geoReplicationLocations: union({ geoReplicationLocations: [] }, account).geoReplicationLocations
        identity: union({ identity: {} }, account).identity
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, account).isAllowTrustedMicrosoftServicesEnabled
        isAnalyticalStorageEnabled: union({ isAnalyticalStorageEnabled: false }, account).isAnalyticalStorageEnabled
        isAutomaticFailoverEnabled: union({ isAutomaticFailoverEnabled: false }, account).isAutomaticFailoverEnabled
        isAzurePortalAccessEnabled: union({ isAzurePortalAccessEnabled: false }, account).isAzurePortalAccessEnabled
        isAzurePublicDatacenterAccessEnabled: union({ isAzurePublicDatacenterAccessEnabled: true }, account).isAzurePublicDatacenterAccessEnabled
        isFreeTierEnabled: union({ isFreeTierEnabled: false }, account).isFreeTierEnabled
        isMultipleWriteLocationsEnabled: union({ isMultipleWriteLocationsEnabled: false }, account).isMultipleWriteLocationsEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, account).isPublicNetworkAccessEnabled
        isServerlessModeEnabled: union({ isServerlessModeEnabled: false }, account).isServerlessModeEnabled
        kind: union({ kind: 'SQL' }, account).kind
        location: union({ location: location }, account).location
        name: union({ name: '${projectName}-cdb-${padLeft(index, 5, '0')}' }, account).name
        tags: union({ tags: {} }, account).tags
        virtualNetworkRules: union({ virtualNetworkRules: [] }, account).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, account).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, account).resourceGroupName)
}]
module diskEncryptionSetsCopy 'br/main:microsoft.compute/disk-encryption-sets:1.0.0' = [for (set, index) in diskEncryptionSets: if (contains(includedTypes, 'microsoft.compute/disk-encryption-sets') && !contains(excludedTypes, 'microsoft.compute/disk-encryption-sets')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-des-${string(index)}'
    params: {
        identity: union({ identity: {} }, set).identity
        keyName: set.keyName
        keyVault: set.keyVault
        keyVersion: union({ keyVersion: '' }, set).keyVersion
        location: union({ location: location }, set).location
        name: union({ name: '${projectName}-des-${padLeft(index, 5, '0')}' }, set).name
        tags: union({ tags: {} }, set).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, set).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, set).resourceGroupName)
}]
module keyVaultsCopy 'br/main:microsoft.key-vault/vaults:1.0.0' = [for (vault, index) in keyVaults: if (contains(includedTypes, 'microsoft.key-vault/vaults') && !contains(excludedTypes, 'microsoft.key-vault/vaults')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-kv-${string(index)}'
    params: {
        firewallRules: union({ firewallRules: [] }, vault).firewallRules
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: true }, vault).isAllowTrustedMicrosoftServicesEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, vault).isPublicNetworkAccessEnabled
        isPurgeProtectionEnabled: union({ isPurgeProtectionEnabled: true }, vault).isPurgeProtectionEnabled
        isRbacAuthorizationEnabled: union({ isRbacAuthorizationEnabled: true }, vault).isRbacAuthorizationEnabled
        isTemplateDeploymentEnabled: union({ isTemplateDeploymentEnabled: true }, vault).isTemplateDeploymentEnabled
        keys: union({ keys: {} }, vault).keys
        location: union({ location: location }, vault).location
        name: union({ name: '${projectName}-kv-${padLeft(index, 5, '0')}' }, vault).name
        secrets: union({ secrets: {} }, vault).secrets
        sku: union({ sku: { name: 'premium' } }, vault).sku
        tags: union({ tags: {} }, vault).tags
        tenantId: union({ tenantId: tenant().tenantId }, vault).tenantId
        virtualNetworkRules: union({ virtualNetworkRules: [] }, vault).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, vault).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, vault).resourceGroupName)
}]
module kubernetesServicesClustersCopy 'br/main:microsoft.container-service/managed-clusters:1.0.0' = [for (cluster, index) in kubernetesServicesClusters: if (contains(includedTypes, 'microsoft.container-service/managed-clusters') && !contains(excludedTypes, 'microsoft.container-service/managed-clusters')) {
    dependsOn: [
        keyVaultsCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-aks-${string(index)}'
    params: {
        addonProfiles: union({ addonProfiles: {} }, cluster).addonProfiles
        agentPoolProfiles: union({ agentPoolProfiles: [] }, cluster).agentPoolProfiles
        diskEncryptionSet: union({ diskEncryptionSet: {} }, cluster).diskEncryptionSet
        identity: cluster.identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, cluster).isPublicNetworkAccessEnabled
        isRbacAuthorizationEnabled: union({ isRbacAuthorizationEnabled: true }, cluster).isRbacAuthorizationEnabled
        location: union({ location: location }, cluster).location
        name: union({ name: '${projectName}-aks-${padLeft(index, 5, '0')}' }, cluster).name
        networkProfile: union({ networkProfile: {} }, cluster).networkProfile
        sku: union({ sku: {
            name: 'Basic'
            tier: 'Free'
        } }, cluster).sku
        tags: union({ tags: {} }, cluster).tags
        version: cluster.version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, cluster).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, cluster).resourceGroupName)
}]
module logAnalyticsWorkspacesCopy 'br/main:microsoft.operational-insights/workspaces:1.0.0' = [for (workspace, index) in logAnalyticsWorkspaces: if (contains(includedTypes, 'microsoft.operational-insights/workspaces') && !contains(excludedTypes, 'microsoft.operational-insights/workspaces')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-law-${string(index)}'
    params: {
        dataRetentionInDays: union({ dataRetentionInDays: 30 }, workspace).dataRetentionInDays
        isDataExportEnabled: union({ isDataExportEnabled: true }, workspace).isDataExportEnabled
        isImmediatePurgeDataOn30DaysEnabled: union({ isImmediatePurgeDataOn30DaysEnabled: true }, workspace).isImmediatePurgeDataOn30DaysEnabled
        isPublicNetworkAccessForIngestionEnabled: union({ isPublicNetworkAccessForIngestionEnabled: false }, workspace).isPublicNetworkAccessForIngestionEnabled
        isPublicNetworkAccessForQueryEnabled: union({ isPublicNetworkAccessForQueryEnabled: false }, workspace).isPublicNetworkAccessForQueryEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, workspace).isSharedKeyAccessEnabled
        location: union({ location: location }, workspace).location
        name: union({ name: '${projectName}-law-${padLeft(index, 5, '0')}' }, workspace).name
        sku: union({ sku: { name: 'PerGB2018' } }, workspace).sku
        tags: union({ tags: {} }, workspace).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, workspace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, workspace).resourceGroupName)
}]
module machineLearningWorkspacesCopy 'br/main:microsoft.machine-learning-services/workspaces:1.0.0' = [for (workspace, index) in machineLearningWorkspaces: if (contains(includedTypes, 'microsoft.machine-learning-services/workspaces') && !contains(excludedTypes, 'microsoft.machine-learning-services/workspaces')) {
    dependsOn: [
        applicationInsightsCopy
        containerRegistriesCopy
        keyVaultsCopy
        logAnalyticsWorkspacesCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
    ]
    name: '${deployment().name}-mlw-${string(index)}'
    params: {
        applicationInsights: workspace.applicationInsights
        computeClusters: union({ computeClusters: [] }, workspace).envicomputeClustersronments
        containerRegistry: workspace.containerRegistry
        environments: union({ environments: [] }, workspace).environments
        identity: workspace.identity
        isHighBusinessImpactFeatureEnabled: union({ isHighBusinessImpactFeatureEnabled: false }, workspace).isHighBusinessImpactFeatureEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, workspace).isPublicNetworkAccessEnabled
        keyVault: workspace.keyVault
        location: union({ location: location }, workspace).location
        name: union({ name: '${projectName}-mlw-${padLeft(index, 5, '0')}' }, workspace).name
        storageAccount: workspace.storageAccount
        sku: union({ sku: { name: 'Basic' } }, workspace).sku
        tags: union({ tags: {} }, workspace).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, workspace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, workspace).resourceGroupName)
}]
module managedApplicationDefinitionsCopy 'br/main:microsoft.solutions/application-definitions:1.0.0' = [for (definition, index) in managedApplicationDefinitions: if (contains(includedTypes, 'microsoft.solutions/application-definitions') && !contains(excludedTypes, 'microsoft.solutions/application-definitions')) {
    dependsOn: [
        storageAccountsCopy
    ]
    name: '${deployment().name}-mad-${string(index)}'
    params: {
        authorizations: union({ authorizations: [] }, definition).authorizations
        description: union({ description: '' }, definition).description
        displayName: union({ displayName: '' }, definition).displayName
        isEnabled: union({ isEnabled: true }, definition).isEnabled
        location: union({ location: location }, definition).location
        lockLevel: union({ lockLevel: 'ReadOnly' }, definition).lockLevel
        name: union({ name: '${projectName}-mad-${padLeft(index, 5, '0')}' }, definition).name
        packageFileUri: definition.packageFileUri
        storageAccount: union({ storageAccount: {} }, definition).storageAccount
        tags: union({ tags: {} }, definition).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, definition).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, definition).resourceGroupName)
}]
module managedApplicationsCopy 'br/main:microsoft.solutions/applications:1.0.0' = [for (application, index) in managedApplications: if (contains(includedTypes, 'microsoft.solutions/applications') && !contains(excludedTypes, 'microsoft.solutions/applications')) {
    dependsOn: [
        managedApplicationDefinitionsCopy
    ]
    name: '${deployment().name}-ma-${string(index)}'
    params: {
        definition: application.definition
        location: union({ location: location }, application).location
        name: union({ name: '${projectName}-ma-${padLeft(index, 5, '0')}' }, application).name
        tags: union({ tags: {} }, application).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, application).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, application).resourceGroupName)
}]
module natGatewaysCopy 'br/main:microsoft.network/nat-gateways:1.0.0' = [for (gateway, index) in natGateways: if (contains(includedTypes, 'microsoft.network/nat-gateways') && !contains(excludedTypes, 'microsoft.network/nat-gateways')) {
    dependsOn: [
        publicIpAddressesCopy
    ]
    name: '${deployment().name}-nat-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, gateway).availabilityZones
        location: union({ location: location }, gateway).location
        name: union({ name: '${projectName}-nat-${padLeft(index, 5, '0')}' }, gateway).name
        publicIpAddresses: union({ publicIpAddresses: [] }, gateway).publicIpAddresses
        publicIpPrefixes: union({ publicIpPrefixes: [] }, gateway).publicIpPrefixes
        tags: union({ tags: {} }, gateway).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module networkInterfacesCopy 'br/main:microsoft.network/network-interfaces:1.0.0' = [for (interface, index) in networkInterfaces: if (contains(includedTypes, 'microsoft.network/network-interfaces') && !contains(excludedTypes, 'microsoft.network/network-interfaces')) {
    dependsOn: [
        networkSecurityGroupsCopy
        routeTablesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-nic-${string(index)}'
    params: {
        dnsServers: union({ dnsServers: [] }, interface).dnsServers
        ipConfigurations: interface.ipConfigurations
        isAcceleratedNetworkingEnabled: union({ isAcceleratedNetworkingEnabled: true }, interface).isAcceleratedNetworkingEnabled
        isIpForwardingEnabled: union({ isIpForwardingEnabled: false }, interface).isIpForwardingEnabled
        location: union({ location: location }, interface).location
        name: union({ name: '${projectName}-nic-${padLeft(index, 5, '0')}' }, interface).name
        networkSecurityGroup: union({ networkSecurityGroup: {} }, interface).networkSecurityGroup
        tags: union({ tags: {} }, interface).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, interface).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, interface).resourceGroupName)
}]
module networkSecurityGroupsCopy 'br/main:microsoft.network/network-security-groups:1.0.0' = [for (group, index) in networkSecurityGroups: if (contains(includedTypes, 'microsoft.network/network-security-groups') && !contains(excludedTypes, 'microsoft.network/network-security-groups')) {
    dependsOn: [ applicationSecurityGroupsCopy ]
    name: '${deployment().name}-nsg-${string(index)}'
    params: {
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-nsg-${padLeft(index, 5, '0')}' }, group).name
        securityRules: group.securityRules
        tags: union({ tags: {} }, group).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module privateDnsZonesCopy 'br/main:microsoft.network/private-dns-zones:1.0.0' = [for (zone, index) in privateDnsZones: if (contains(includedTypes, 'microsoft.network/private-dns-zones') && !contains(excludedTypes, 'microsoft.network/private-dns-zones')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-dnsi-${string(index)}'
    params: {
        aRecords: union({ aRecords: [] }, zone).aRecords
        name: zone.name
        tags: union({ tags: {} }, zone).tags
        virtualNetworkLinks: union({ virtualNetworkLinks: [] }, zone).virtualNetworkLinks
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, zone).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, zone).resourceGroupName)
}]
module privateEndpointsCopy 'br/main:microsoft.network/private-endpoints:1.0.0' = [for (endpoint, index) in privateEndpoints: if (contains(includedTypes, 'microsoft.network/private-endpoints') && !contains(excludedTypes, 'microsoft.network/private-endpoints')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        routeTablesCopy
        storageAccountsCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-pe-${string(index)}'
    params: {
        applicationSecurityGroups: union({ applicationSecurityGroups: [] }, endpoint).applicationSecurityGroups
        location: location
        name: endpoint.name
        resource: endpoint.resource
        subnet: endpoint.subnet
        tags: union({ tags: {} }, endpoint).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, endpoint).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, endpoint).resourceGroupName)
}]
module proximityPlacementGroupsCopy 'br/main:microsoft.compute/proximity-placement-groups:1.0.0' = [for (group, index) in proximityPlacementGroups: if (contains(includedTypes, 'microsoft.compute/proximity-placement-groups') && !contains(excludedTypes, 'microsoft.compute/proximity-placement-groups')) {
    name: '${deployment().name}-ppg-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, group).availabilityZones
        location: union({ location: location }, group).location
        name: union({ name: '${projectName}-ppg-${padLeft(index, 5, '0')}' }, group).name
        tags: union({ tags: {} }, group).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, group).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, group).resourceGroupName)
}]
module publicDnsZonesCopy 'br/main:microsoft.network/dns-zones:1.0.0' = [for (zone, index) in publicDnsZones: if (contains(includedTypes, 'microsoft.network/dns-zones') && !contains(excludedTypes, 'microsoft.network/dns-zones')) {
    name: '${deployment().name}-dnse-${string(index)}'
    params: {
        cnameRecords: union({ cnameRecords: [] }, zone).cnameRecords
        name: zone.name
        tags: union({ tags: {} }, zone).tags
        txtRecords: union({ txtRecords: [] }, zone).txtRecords
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, zone).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, zone).resourceGroupName)
}]
module publicIpAddressesCopy 'br/main:microsoft.network/public-ip-addresses:1.0.0' = [for (address, index) in publicIpAddresses: if (contains(includedTypes, 'microsoft.network/public-ip-addresses') && !contains(excludedTypes, 'microsoft.network/public-ip-addresses')) {
    name: '${deployment().name}-pip-${string(index)}'
    params: {
        allocationMethod: address.allocationMethod
        availabilityZones: union({ availabilityZones: [] }, address).availabilityZones
        ipPrefix: union({ ipPrefix: {} }, address).ipPrefix
        location: union({ location: location }, address).location
        name: union({ name: '${projectName}-pip-${padLeft(index, 5, '0')}' }, address).name
        sku: address.sku
        tags: union({ tags: {} }, address).tags
        version: union({ version: 'IPv4' }, address).version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, address).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, address).resourceGroupName)
}]
module publicIpPrefixesCopy 'br/main:microsoft.network/public-ip-prefixes:1.0.0' = [for (prefix, index) in publicIpPrefixes: if (contains(includedTypes, 'microsoft.network/public-ip-prefixes') && !contains(excludedTypes, 'microsoft.network/public-ip-prefixes')) {
    name: '${deployment().name}-pipp-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, prefix).availabilityZones
        location: union({ location: location }, prefix).location
        name: union({ name: '${projectName}-pipp-${padLeft(index, 5, '0')}' }, prefix).name
        size: prefix.size
        sku: prefix.sku
        tags: union({ tags: {} }, prefix).tags
        version: union({ version: 'IPv4' }, prefix).version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, prefix).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, prefix).resourceGroupName)
}]
module redisCachesCopy 'br/main:microsoft.cache/redis:1.0.0' = [for (cache, index) in redisCaches: if (contains(includedTypes, 'microsoft.cache/redis') && !contains(excludedTypes, 'microsoft.cache/redis')) {
    dependsOn: [
        virtualNetworksCopy
    ]
    name: '${deployment().name}-redis-${string(index)}'
    params: {
        availabilityZones: union({ availabilityZones: [] }, cache).availabilityZones
        configuration: union({ configuration: {} }, cache).configuration
        firewallRules: union({ firewallRules: [] }, cache).firewallRules
        identity: union({ identity: {} }, cache).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, cache).isPublicNetworkAccessEnabled
        location: union({ location: location }, cache).location
        name: union({ name: '${projectName}-redis-${padLeft(index, 5, '0')}' }, cache).name
        numberOfShards: union({ numberOfShards: 0 }, cache).numberOfShards
        sku: union({ sku: {
            capacity: 0
            family: 'C'
            name: 'Standard'
        } }, cache).sku
        subnet: union({ subnet: {} }, cache).subnet
        tags: union({ tags: {} }, cache).tags
        version: union({ version: 'latest' }, cache).version
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, cache).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, cache).resourceGroupName)
}]
module routeTablesCopy 'br/main:microsoft.network/route-tables:1.0.0' = [for (route, index) in routeTables: if (contains(includedTypes, 'microsoft.network/route-tables') && !contains(excludedTypes, 'microsoft.network/route-tables')) {
    name: '${deployment().name}-rt-${string(index)}'
    params: {
        location: union({ location: location }, route).location
        name: union({ name: '${projectName}-ppg-${padLeft(index, 5, '0')}' }, route).name
        routes: union({ routes: [] }, route).routes
        tags: union({ tags: {} }, route).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, route).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, route).resourceGroupName)
}]
module serviceBusNamespacesCopy 'br/main:microsoft.service-bus/namespaces:1.0.0' = [for (namespace, index) in serviceBusNamespaces: if (contains(includedTypes, 'microsoft.service-bus/namespaces') && !contains(excludedTypes, 'microsoft.service-bus/namespaces')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sb-${string(index)}'
    params: {
        identity: union({ identity: {} }, namespace).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, namespace).isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, namespace).isSharedKeyAccessEnabled
        isZoneRedundancyEnabled: union({ isZoneRedundancyEnabled: true }, namespace).isZoneRedundancyEnabled
        location: union({ location: location }, namespace).location
        name: union({ name: '${projectName}-sb-${padLeft(index, 5, '0')}' }, namespace).name
        sku: union({ sku: { name: 'Premium' } }, namespace).sku
        tags: union({ tags: {} }, namespace).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, namespace).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, namespace).resourceGroupName)
}]
module signalrServicesCopy 'br/main:microsoft.signalr-service/signalr:1.0.0' = [for (service, index) in signalrServices: if (contains(includedTypes, 'microsoft.signalr-service/signalr') && !contains(excludedTypes, 'microsoft.signalr-service/signalr')) {
    dependsOn: [
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sglr-${string(index)}'
    params: {
        cors: union({ cors: {} }, service).cors
        identity: union({ identity: {} }, service).identity
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, service).isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, service).isSharedKeyAccessEnabled
        location: union({ location: location }, service).location
        name: union({ name: '${projectName}-sglr-${padLeft(index, 5, '0')}' }, service).name
        serverless: union({ serverless: {} }, service).serverless
        sku: union({ sku: { name: 'Standard_S1' } }, service).sku
        tags: union({ tags: {} }, service).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, service).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, service).resourceGroupName)
}]
module sqlServersCopy 'br/main:microsoft.sql/servers:1.0.0' = [for (server, index) in sqlServers: if (contains(includedTypes, 'microsoft.sql/servers') && !contains(excludedTypes, 'microsoft.sql/servers')) {
    dependsOn: [
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-sql-${string(index)}'
    params: {
        administrator: union({ name: uniqueString('${projectName}-sql-${padLeft(index, 5, '0')}') }, server.administrator)
        firewallRules: union({ firewallRules: [] }, server).firewallRules
        identity: union({ identity: {} }, server).identity
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, server).isAllowTrustedMicrosoftServicesEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, server).isPublicNetworkAccessEnabled
        isSqlAuthenticationEnabled: union({ isSqlAuthenticationEnabled: false }, server).isSqlAuthenticationEnabled
        location: union({ location: location }, server).location
        name: union({ name: '${projectName}-sql-${padLeft(index, 5, '0')}' }, server).name
        tags: union({ tags: {} }, server).tags
        virtualNetworkRules: union({ virtualNetworkRules: [] }, server).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, server).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, server).resourceGroupName)
}]
module storageAccountsCopy 'br/main:microsoft.storage/storage-accounts:1.0.0' = [for (account, index) in storageAccounts: if (contains(includedTypes, 'microsoft.storage/storage-accounts') && !contains(excludedTypes, 'microsoft.storage/storage-accounts')) {
    dependsOn: [
        keyVaultsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-data-${string(index)}'
    params: {
        accessTier: union({ accessTier: 'Hot' }, account).accessTier
        firewallRules: union({ firewallRules: [] }, account).firewallRules
        identity: union({ identity: {} }, account).identity
        isAllowTrustedMicrosoftServicesEnabled: union({ isAllowTrustedMicrosoftServicesEnabled: false }, account).isAllowTrustedMicrosoftServicesEnabled
        isHttpsOnlyModeEnabled: union({ isHttpsOnlyModeEnabled: true }, account).isHttpsOnlyModeEnabled
        isPublicNetworkAccessEnabled: union({ isPublicNetworkAccessEnabled: false }, account).isPublicNetworkAccessEnabled
        isSharedKeyAccessEnabled: union({ isSharedKeyAccessEnabled: false }, account).isSharedKeyAccessEnabled
        kind: account.kind
        location: union({ location: location }, account).location
        name: union({ name: '${projectName}data${padLeft(index, 5, '0')}' }, account).name
        services: account.services
        sku: account.sku
        tags: union({ tags: {} }, account).tags
        virtualNetworkRules: union({ virtualNetworkRules: [] }, account).virtualNetworkRules
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, account).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, account).resourceGroupName)
}]
module userAssignedIdentitiesCopy 'br/main:microsoft.managed-identity/user-assigned-identities:1.0.0' = [for (identity, index) in userAssignedIdentities: if (contains(includedTypes, 'microsoft.managed-identity/user-assigned-identities') && !contains(excludedTypes, 'microsoft.managed-identity/user-assigned-identities')) {
    name: '${deployment().name}-mi-${string(index)}'
    params: {
        location: union({ location: location }, identity).location
        name: union({ name: '${projectName}-mi-${padLeft(index, 5, '0')}' }, identity).name
        tags: union({ tags: {} }, identity).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, identity).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, identity).resourceGroupName)
}]
module virtualMachinesCopy 'br/main:microsoft.compute/virtual-machines:1.0.0' = [for (machine, index) in virtualMachines: if (contains(includedTypes, 'microsoft.compute/virtual-machines') && !contains(excludedTypes, 'microsoft.compute/virtual-machines')) {
    dependsOn: [
        applicationSecurityGroupsCopy
        availabilitySetsCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        proximityPlacementGroupsCopy
        privateDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-vm-${string(index)}'
    params: {
        administrator: machine.administrator
        availabilitySet: union({ availabilitySet: {} }, machine).availabilitySet
        availabilityZones: union({ availabilityZones: [] }, machine).availabilityZones
        identity: union({ identity: {} }, machine).identity
        imageReference: machine.imageReference
        linuxConfiguration: union({ linuxConfiguration: {} }, machine).linuxConfiguration
        location: union({ location: location }, machine).location
        name: union({ name: '${projectName}vm${padLeft(index, 5, '0')}' }, machine).name
        networkInterfaces: machine.networkInterfaces
        proximityPlacementGroup: union({ proximityPlacementGroup: {} }, machine).proximityPlacementGroup
        sku: machine.sku
        subnet: union({ subnet: {} }, machine).subnet
        tags: union({ tags: {} }, machine).tags
        windowsConfiguration: union({ windowsConfiguration: {} }, machine).windowsConfiguration
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, machine).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, machine).resourceGroupName)
}]
module virtualNetworkGatewaysCopy 'br/main:microsoft.network/virtual-network-gateways:1.0.0' = [for (gateway, index) in virtualNetworkGateways: if (contains(includedTypes, 'microsoft.network/virtual-network-gateways') && !contains(excludedTypes, 'microsoft.network/virtual-network-gateways')) {
    dependsOn: [
        publicIpAddressesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-vng-${string(index)}'
    params: {
        clientConfiguration: gateway.clientConfiguration
        generation: gateway.generation
        ipConfigurations: gateway.ipConfigurations
        isActiveActiveModeEnabled: gateway.isActiveActiveModeEnabled
        location: union({ location: location }, gateway).location
        mode: gateway.mode
        name: union({ name: '${projectName}-vng-${padLeft(index, 5, '0')}' }, gateway).name
        sku: gateway.sku
        tags: union({ tags: {} }, gateway).tags
        type: gateway.type
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, gateway).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, gateway).resourceGroupName)
}]
module virtualNetworksCopy 'br/main:microsoft.network/virtual-networks:1.0.0' = [for (network, index) in virtualNetworks: if (contains(includedTypes, 'microsoft.network/virtual-networks') && !contains(excludedTypes, 'microsoft.network/virtual-networks')) {
    dependsOn: [
        natGatewaysCopy
        networkSecurityGroupsCopy
        routeTablesCopy
    ]
    name: '${deployment().name}-vnet-${string(index)}'
    params: {
        addressPrefixes: network.addressPrefixes
        ddosProtectionPlan: {}
        dnsServers: network.dnsServers
        location: union({ location: location }, network).location
        name: union({ name: '${projectName}-vnet-${padLeft(index, 5, '0')}' }, network).name
        subnets: network.subnets
        tags: union({ tags: {} }, network).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, network).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, network).resourceGroupName)
}]
module webApplicationsCopy 'br/main:microsoft.web/sites:1.0.0' = [for (application, index) in webApplications: if (contains(includedTypes, 'microsoft.web/sites') && !contains(excludedTypes, 'microsoft.web/sites')) {
    dependsOn: [
        applicationConfigurationStoresCopy
        applicationInsightsCopy
        applicationServiceEnvironmentsCopy
        applicationServicePlansCopy
        keyVaultsCopy
        privateDnsZonesCopy
        publicDnsZonesCopy
        serviceBusNamespacesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualNetworksCopy
    ]
    name: '${deployment().name}-web-${string(index)}'
    params: {
        applicationInsights: union({ applicationInsights: {} }, application).applicationInsights
        applicationSettings: union({ applicationSettings: {} }, application).applicationSettings
        cors: union({ cors: {} }, application).cors
        functionExtension: union({ functionExtension: {} }, application).functionExtension
        identity: union({ identity: {} }, application).identity
        is32BitModeEnabled: union({ is32BitModeEnabled: false }, application).is32BitModeEnabled
        location: union({ location: location }, application).location
        name: union({ name: '${projectName}-web-${padLeft(index, 5, '0')}' }, application).name
        servicePlan: application.servicePlan
        tags: union({ tags: {} }, application).tags
    }
    scope: resourceGroup(union({
        subscriptionId: subscription().subscriptionId
    }, application).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, application).resourceGroupName)
}]

resource deploymentsCopy 'Microsoft.Resources/deployments@2021-04-01' = [for (deployment, index) in deployments: if (contains(includedTypes, 'microsoft.resources/deployments') && !contains(excludedTypes, 'microsoft.resources/deployments')) {
    dependsOn: [
        apiManagementServicesCopy
        applicationConfigurationStoresCopy
        applicationGatewaysCopy
        applicationInsightsCopy
        applicationSecurityGroupsCopy
        applicationServiceEnvironmentsCopy
        applicationServicePlansCopy
        availabilitySetsCopy
        containerRegistriesCopy
        cosmosDbAccountsCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        kubernetesServicesClustersCopy
        logAnalyticsWorkspacesCopy
        machineLearningWorkspacesCopy
        managedApplicationDefinitionsCopy
        managedApplicationsCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        privateDnsZonesCopy
        privateEndpointsCopy
        proximityPlacementGroupsCopy
        publicDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        roleAssignmentsCopy
        routeTablesCopy
        serviceBusNamespacesCopy
        signalrServicesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualMachinesCopy
        virtualNetworkGatewaysCopy
        virtualNetworksCopy
        webApplicationsCopy
    ]
    name: '${deployment().name}-rm-${string(index)}'
    properties: {
        expressionEvaluationOptions: {
            scope: 'NotSpecified'
        }
        mode: union({ mode: 'Incremental' }, deployment).mode
        parameters: union({ parameters: {} }, deployment).parameters
        parametersLink: union({ parametersLink: null }, deployment).parametersLink
        template: union({ template: null }, deployment).template
        templateLink: union({ templateLink: null }, deployment).templateLink
    }
    resourceGroup: union({ resourceGroupName: resourceGroup().name }, deployment).resourceGroupName
    subscriptionId: union({ subscriptionId: subscription().subscriptionId }, deployment).subscriptionId
}]
resource roleAssignmentsCopy 'Microsoft.Resources/deployments@2021-04-01' = [for (assignment, index) in roleAssignments: if (contains(includedTypes, 'microsoft.authorization/role-assignments') && !contains(excludedTypes, 'microsoft.authorization/role-assignments')) {
    dependsOn: [
        apiManagementServicesCopy
        applicationConfigurationStoresCopy
        applicationGatewaysCopy
        applicationInsightsCopy
        applicationSecurityGroupsCopy
        applicationServiceEnvironmentsCopy
        applicationServicePlansCopy
        availabilitySetsCopy
        containerRegistriesCopy
        cosmosDbAccountsCopy
        diskEncryptionSetsCopy
        keyVaultsCopy
        kubernetesServicesClustersCopy
        logAnalyticsWorkspacesCopy
        machineLearningWorkspacesCopy
        managedApplicationDefinitionsCopy
        managedApplicationsCopy
        natGatewaysCopy
        networkInterfacesCopy
        networkSecurityGroupsCopy
        privateDnsZonesCopy
        privateEndpointsCopy
        proximityPlacementGroupsCopy
        publicDnsZonesCopy
        publicIpAddressesCopy
        publicIpPrefixesCopy
        routeTablesCopy
        serviceBusNamespacesCopy
        signalrServicesCopy
        sqlServersCopy
        storageAccountsCopy
        userAssignedIdentitiesCopy
        virtualMachinesCopy
        virtualNetworkGatewaysCopy
        virtualNetworksCopy
        webApplicationsCopy
    ]
    name: '${deployment().name}-rbac-${string(index)}'
    properties: {
        expressionEvaluationOptions: {
            scope: 'NotSpecified'
        }
        mode: 'Incremental'
        parameters: {
            assignee: {
                value: assignment.assignee
            }
            assignor: {
                value: assignment.assignor
            }
            roleDefinitionName: {
                value: assignment.roleDefinitionName
            }
        }
        templateLink: {
            contentVersion: '1.0.0.0'
            id: resourceId('fd49ea67-135b-449f-a62c-3e4b8d26d3d6', 'thelankrew', 'Microsoft.Resources/templateSpecs/versions', 'microsoft.authorization_role-assignments', '1.0.0')
        }
    }
    resourceGroup: resourceGroup().name
    subscriptionId: subscription().subscriptionId
}]
