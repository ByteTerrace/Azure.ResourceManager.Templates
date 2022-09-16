@description('An object that encapsulates the properties of the addons that will be configured on the Azure Kubernetes Services Cluster.')
param addonProfiles object = {}
@description('An array of agent pool profiles that will be deployed within the Azure Kubernetes Services Cluster.')
param agentPoolProfiles array = []
@description('An object that encapsulates the properties of the Azure Disk Encryption Set that will be associated with the Azure Kubernetes Services Cluster.')
param diskEncryptionSet object = {}
@description('An object that encapsulates the properties of the identity that will be assigned to the Azure Kubernetes Services Cluster.')
param identity object
@description('Indicates whether the Azure Kubernetes Service Cluster is accessible from the internet.')
param isPublicNetworkAccessEnabled bool = false
@description('Indicates whether the role-based access control feature is enabled on the Azure Kubernetes Services Cluster.')
param isRbacAuthorizationEnabled bool = true
@description('Specifies the location in which the Azure Kubernetes Services Cluster resource(s) will be deployed.')
param location string = resourceGroup().location
@description('Specifies the name of the Azure Kubernetes Services Cluster.')
param name string
@description('An object that encapsulates the networking properties of the the Azure Kubernetes Services Cluster.')
param networkProfile object = {}
@description('Specifies the SKU of the Azure Kubernetes Services Cluster.')
param sku object = {
    name: 'Basic'
    tier: 'Free'
}
@description('Specifies the set of tag key-value pairs that will be assigned to the Azure Kubernetes Services Cluster.')
param tags object = {}
@description('Specifies the version of the Azure Kubernetes Services Cluster.')
param version string

var default = {
    networkProfile: {
        dnsServiceIpAddress: null
        dockerBridgeCidr: null
        loadBalancerSku: 'standard'
        mode: 'transparent'
        outboundType: 'loadBalancer'
        plugin: 'kubenet'
        podCidrs: []
        policy: 'calico'
        serviceCidrs: []
    }
}
var isAzureKeyVaultSecretsProviderAddonProfileEmpty = !contains(addonProfiles, 'azureKeyVaultSecretsProvider')
var isLogAnalyticsWorkspaceAddonProfileEmpty = !contains(addonProfiles, 'logAnalyticsWorkspace')
var userAssignedIdentities = [for managedIdentity in union({
  userAssignedIdentities: []
}, identity).userAssignedIdentities: extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', union({
  subscriptionId: subscription().subscriptionId
}, managedIdentity).subscriptionId, union({
  resourceGroupName: resourceGroup().name
}, managedIdentity).resourceGroupName), 'Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentity.name)]

resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-07-02-preview' = {
    identity: {
        type: union({ type: empty(userAssignedIdentities) ? 'None' : 'UserAssigned' }, identity).type
        userAssignedIdentities: empty(userAssignedIdentities) ? null : json(replace(replace(replace(string(userAssignedIdentities), '",', '":{},'), '[', '{'), ']', ':{}}'))
    }
    location: location
    name: name
    properties: {
        aadProfile: isRbacAuthorizationEnabled ? {
            adminGroupObjectIDs: []
            enableAzureRBAC: isRbacAuthorizationEnabled
            managed: true
            tenantID: tenant().tenantId
        } : null
        addonProfiles: {
            azureKeyvaultSecretsProvider: {
                config: isAzureKeyVaultSecretsProviderAddonProfileEmpty ? null : {
                    enableSecretRotation: string(true)
                    rotationPollInterval: '3m'
                }
                enabled: union({ isEnabled: true }, addonProfiles).azureKeyVaultSecretsProvider.isEnabled
            }
            azurePolicy: {
                enabled: union({ isEnabled: true }, addonProfiles).azurePolicy.isEnabled
            }
            httpApplicationRouting: {
                enabled: union({ isEnabled: true }, addonProfiles).httpApplicationRouting.isEnabled
            }
            omsAgent: {
                config: isLogAnalyticsWorkspaceAddonProfileEmpty ? null : {
                    logAnalyticsWorkspaceResourceID: resourceId(union({
                        subscriptionId: subscription().subscriptionId
                    }, addonProfiles.logAnalyticsWorkspace).subscriptionId, union({
                        resourceGroupName: resourceGroup().name
                    }, addonProfiles.logAnalyticsWorkspace).resourceGroupName, 'Microsoft.OperationalInsights/workspaces', addonProfiles.logAnalyticsWorkspace.name)
                    useAADAuth: string(true)
                }
                enabled: union({ logAnalyticsWorkspace: { isEnabled: !isLogAnalyticsWorkspaceAddonProfileEmpty } }, addonProfiles).logAnalyticsWorkspace.isEnabled
            }
        }
        agentPoolProfiles: [for profile in (empty(agentPoolProfiles) ? [{
            count: 1
            mode: 'System'
            name: 'main'
            virtualMachineSize: 'Standard_B2ms'
        }] : agentPoolProfiles): {
            availabilityZones: union({ availabilityZones: null }, profile).availabilityZones
            count: profile.count
            enableAutoScaling: union({ isAutoScalingEnabled: null }, profile).isAutoScalingEnabled
            enableEncryptionAtHost: union({ isEncryptionAtHostEnabled: null }, profile).isEncryptionAtHostEnabled
            enableFIPS: union({ isFipsSupportEnabled: null }, profile).isFipsSupportEnabled
            enableNodePublicIP: union({ isPublicIpAddressEnabled: null }, profile).isPublicIpAddressEnabled
            enableUltraSSD: union({ isUltraSsdSupportEnabled: null }, profile).isUltraSsdSupportEnabled
            nodeLabels: union({ labels: null }, profile).labels
            nodeTaints: union({ taints: null }, profile).taints
            maxCount: union({ maximumCount: null }, profile).maximumCount
            maxPods: union({ maximumPodCount: null }, profile).maximumPodCount
            minCount: union({ minimumCount: null }, profile).minimumCount
            mode: profile.mode
            name: profile.name
            osType: union({ osType: null }, profile).osType
            type: union({ type: null }, profile).type
            vmSize: profile.virtualMachineSize
        }]
        apiServerAccessProfile: {
            authorizedIPRanges: null
            disableRunCommand: false
            enablePrivateCluster: isPublicNetworkAccessEnabled
            enablePrivateClusterPublicFQDN: false
            enableVnetIntegration: false
        }
        disableLocalAccounts: isRbacAuthorizationEnabled
        diskEncryptionSetID: empty(diskEncryptionSet) ? null : resourceId(union({
            subscriptionId: subscription().subscriptionId
        }, diskEncryptionSet).subscriptionId, union({
            resourceGroupName: resourceGroup().name
        }, diskEncryptionSet).resourceGroupName, 'Microsoft.Compute/diskEncryptionSets', diskEncryptionSet.name)
        dnsPrefix: toLower(name)
        enableRBAC: isRbacAuthorizationEnabled
        kubernetesVersion: version
        networkProfile: {
            dnsServiceIP: union(default.networkProfile, networkProfile).dnsServiceIpAddress
            dockerBridgeCidr: union(default.networkProfile, networkProfile).dockerBridgeCidr
            loadBalancerSku: toLower(union(default.networkProfile, networkProfile).loadBalancerSku)
            networkMode: ('azure' == toLower(default.networkProfile.plugin)) ? toLower(union(default.networkProfile, networkProfile).mode) : null
            networkPlugin: union(default.networkProfile, networkProfile).plugin
            networkPolicy: toLower(union(default.networkProfile, networkProfile).policy)
            outboundType: union(default.networkProfile, networkProfile).outboundType
            podCidr: (1 == length(union(default.networkProfile, networkProfile).podCidrs)) ? networkProfile.podCidrs[0] : null
            podCidrs: (1 < length(union(default.networkProfile, networkProfile).podCidrs)) ? networkProfile.podCidrs : null
            serviceCidr: (1 == length(union(default.networkProfile, networkProfile).serviceCidrs)) ? networkProfile.serviceCidrs[0] : null
            serviceCidrs: (1 < length(union(default.networkProfile, networkProfile).serviceCidrs)) ? networkProfile.serviceCidrs : null
        }
    }
    sku: sku
    tags: tags
}
