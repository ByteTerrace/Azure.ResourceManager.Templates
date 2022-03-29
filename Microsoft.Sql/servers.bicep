@description('An object that encapsulates the properties of the Active Directory administrator that will be assigned to the Azure SQL Server.')
param activeDirectoryAdministrator object = {}
@description('An object that encapsulates the audit settings that will be applied to the Azure SQL Server.')
param audit object = {}
@description('Specifies how clients will connect to the Azure SQL Server.')
param connectionPolicy string = 'Default'
@description('An array of dns aliases that will be assigned to the Azure SQL Server.')
param dnsAliases array = []
@description('An array of elastic pools that will be created within the Azure SQL Server.')
param elasticPools array = []
@description('An object that encapsulates the properties of the firewall rules that will be assigned to the Azure SQL Server.')
param firewallRules object = {}
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure SQL Server.')
param identity object = {}
@description('Indicates whether trusted Microsoft services are allowed to access the Azure SQL Server.')
param isAllowTrustedMicrosoftServicesEnabled bool = false
@description('Indicates whether the Azure SQL Server is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Specifies the location in which the Azure SQL Server resource(s) will be deployed.')
param location string
@maxLength(63)
@minLength(1)
@description('Specifies the name of the Azure SQL Server.')
param name string
@description('An object that encapsulates the properties of the SQL administrator that will be assigned to the Azure SQL Server.')
@secure()
param sqlAdministrator object = {}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure SQL Server.')
param tags object = {}
@description('An array of virtual network rules that will be assigned to the Azure SQL Server.')
param virtualNetworkRules array = []

var defaults = {
    audit: {
        logAnalyticsWorkspace: {}
        logs: []
        metrics: []
        storageAccount: {}
    }
    firewallRules: {
        inbound: []
        outbound: []
    }
}
var auditWithDefaults = union(defaults.audit, audit)
var firewalLRulesWithDefaults = union(defaults.firewallRules, firewallRules)
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: resourceId(union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName, 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource server 'Microsoft.Sql/servers@2021-08-01-preview' = {
    identity: {
        type: union({
            type: (empty(userAssignedIdentities) ? 'None' : 'UserAssigned')
        }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        administratorLogin: (empty(sqlAdministrator) ? null : sqlAdministrator.name)
        administratorLoginPassword: (empty(sqlAdministrator) ? null : sqlAdministrator.password)
        administrators: (empty(activeDirectoryAdministrator) ? null : {
            administratorType: 'ActiveDirectory'
            azureADOnlyAuthentication: (!union({
                isEnabled: (!empty(sqlAdministrator))
            }, sqlAdministrator).isEnabled)
            login: activeDirectoryAdministrator.name
            principalType: null
            sid: activeDirectoryAdministrator.objectId
            tenantId: union({
                tenantId: tenant().tenantId
            }, activeDirectoryAdministrator).tenantId
        })
        federatedClientId: null
        keyId: null
        minimalTlsVersion: '1.2'
        primaryUserAssignedIdentityId: (empty(userAssignedIdentities) ? null : first(userAssignedIdentities))
        publicNetworkAccess: (isPublicNetworkAccessEnabled ? 'Enabled': 'Disabled')
        restrictOutboundNetworkAccess: (isPublicNetworkAccessEnabled && empty(union({
            outbound: []
        }, firewallRules).outbound) ? 'Disabled': 'Enabled')
        version: '12.0'
    }
    tags: tags
}

resource masterDatabase 'Microsoft.Sql/servers/databases@2021-08-01-preview' existing = {
    name: 'master'
    parent: server
}

resource azureActiveDirectoryOnlyAuthentication 'Microsoft.Sql/servers/azureADOnlyAuthentications@2021-08-01-preview' = {
    name: 'Default'
    parent: server
    properties: {
        azureADOnlyAuthentication: (!union({
            isEnabled: (!empty(sqlAdministrator))
        }, sqlAdministrator).isEnabled)
    }
}

resource administrator 'Microsoft.Sql/servers/administrators@2021-08-01-preview' = {
    dependsOn: [
        azureActiveDirectoryOnlyAuthentication
    ]
    name: 'ActiveDirectory'
    parent: server
    properties: {
        administratorType: 'ActiveDirectory'
        login: activeDirectoryAdministrator.name
        sid: activeDirectoryAdministrator.objectId
        tenantId: union({
            tenantId: tenant().tenantId
        }, activeDirectoryAdministrator).tenantId
    }
}

resource serverDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!(empty(auditWithDefaults.storageAccount) && empty(auditWithDefaults.logAnalyticsWorkspace))) {
    dependsOn: [
        administrator
    ]
    name: 'audit'
    properties: {
        eventHubAuthorizationRuleId: null
        eventHubName: null
        logAnalyticsDestinationType: union({
            destinationType: null
        }, auditWithDefaults.logAnalyticsWorkspace).destinationType
        logs: [for log in auditWithDefaults.logs: {
            category: log.name
            enabled: union({
                isEnabled: true
            }, log).isEnabled
        }]
        marketplacePartnerId: null
        metrics: [for metric in auditWithDefaults.metrics: {
            category: metric.name
            enabled: union({
                isEnabled: true
            }, metric).isEnabled
        }]
        serviceBusRuleId: null
        storageAccountId: (empty(auditWithDefaults.storageAccount) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, auditWithDefaults.storageAccount).resourceGroupName, 'Microsoft.Storage/storageAccounts', auditWithDefaults.storageAccount.name))
        workspaceId: (empty(auditWithDefaults.logAnalyticsWorkspace) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, {}).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, auditWithDefaults.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', auditWithDefaults.logAnalyticsWorkspace.name))
    }
    scope: masterDatabase
}

resource connectionPolicySettings 'Microsoft.Sql/servers/connectionPolicies@2021-08-01-preview' = {
    dependsOn: [
        administrator
    ]
    name: 'default'
    parent: server
    properties: {
        connectionType: connectionPolicy
    }
}

resource dnsAliasesCopy 'Microsoft.Sql/servers/dnsAliases@2021-08-01-preview' = [for alias in dnsAliases: {
    dependsOn: [
        connectionPolicySettings
    ]
    name: '${alias}'
    parent: server
}]

resource trustedMicrosoftServicesFirewallRule 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = if (isAllowTrustedMicrosoftServicesEnabled) {
    name: 'AllowAllWindowsAzureIps'
    parent: server
    properties: {
        endIpAddress: '0.0.0.0'
        startIpAddress: '0.0.0.0'
    }
}

resource inboundFirewallRules 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = [for rule in firewalLRulesWithDefaults.inbound: {
    dependsOn: [
        connectionPolicySettings
        dnsAliasesCopy
        trustedMicrosoftServicesFirewallRule
    ]
    name: '${rule.name}'
    parent: server
    properties: {
        endIpAddress: rule.endIpAddress
        startIpAddress: rule.startIpAddress
    }
}]

resource virtualNetworkRulesCopy 'Microsoft.Sql/servers/virtualNetworkRules@2021-08-01-preview' = [for rule in virtualNetworkRules: {
    dependsOn: [
        connectionPolicySettings
        dnsAliasesCopy
        inboundFirewallRules
        trustedMicrosoftServicesFirewallRule
    ]
    name: '${rule.name}'
    parent: server
    properties: {
        ignoreMissingVnetServiceEndpoint: false
        virtualNetworkSubnetId: resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, rule.subnet).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, rule.subnet).resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', rule.subnet.virtualNetworkName, rule.subnet.name)
    }
}]

resource outboundFirewallRules 'Microsoft.Sql/servers/outboundFirewallRules@2021-08-01-preview' = [for rule in firewalLRulesWithDefaults.outbound: {
    dependsOn: [
        connectionPolicySettings
        dnsAliasesCopy
        inboundFirewallRules
        trustedMicrosoftServicesFirewallRule
        virtualNetworkRulesCopy
    ]
    name: rule.fullyQualifiedDomainName
    parent: server
}]

resource elasticPoolsCopy 'Microsoft.Sql/servers/elasticPools@2021-08-01-preview' = [for pool in elasticPools: {
    dependsOn: [
        connectionPolicySettings
        dnsAliasesCopy
        inboundFirewallRules
        outboundFirewallRules
        trustedMicrosoftServicesFirewallRule
        virtualNetworkRulesCopy
    ]
    location: location
    name: '${pool.name}'
    parent: server
    properties: {
        licenseType: (union({
            isAzureHybridBenefitEnabled: false
        }, pool).isAzureHybridBenefitEnabled ? 'BasePrice' : 'LicenseIncluded')
        maintenanceConfigurationId: (empty(union({
            maintenancePlan: {}
        }, pool).maintenancePlan) ? subscriptionResourceId('Microsoft.Maintenance/publicMaintenanceConfigurations', 'SQL_Default') : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, pool.maintenancePlan).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, pool.maintenancePlan).resourceGroupName, 'Microsoft.Maintenance/maintenanceConfigurations', pool.maintenancePlan.name))
        maxSizeBytes: union({
            maximumSizeInBytes: 268435456000
        }, pool).maximumSizeInBytes
        perDatabaseSettings: {
            maxCapacity: union({
                perDatabaseSettings: {
                    maximumNumberOfCapacityUnits: last(split(pool.skuName, '_'))
                }
            }, pool).perDatabaseSettings.maximumNumberOfCapacityUnits
            minCapacity: union({
                perDatabaseSettings: {
                    minimumNumberOfCapacityUnits: 0
                }
            }, pool).perDatabaseSettings.minimumNumberOfCapacityUnits
        }
        zoneRedundant: union({
            isZoneRedundant: false
        }, pool).isZoneRedundant
    }
    sku: {
        capacity: last(split(pool.skuName, '_'))
        name: substring(pool.skuName, 0, lastIndexOf(pool.skuName, '_'))
    }
    tags: tags
}]
