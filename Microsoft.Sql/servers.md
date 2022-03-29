# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'SqlServer-Example';
$parameters = @{
    activeDirectoryAdministrator = @{ # Required (if sqlAdministrator is empty)
        value = @{
            name = '<Name>';
            objectId = '<ObjectId>';
        };
    };
    audit = @{ # Optional
        value = @{
            <#logAnalyticsWorkspace = @{
                name = '<Name>';
                resourceGroupName = '<ResourceGroupName>';
                subscriptionId = '<SubscriptionId>;
            };#>
            logs = @(
                @{
                    isEnabled = $false;
                    name = 'AutomaticTuning';
                },
                @{
                    isEnabled = $false;
                    name = 'Blocks';
                },
                @{
                    isEnabled = $false;
                    name = 'DatabaseWaitStatistics';
                },
                @{
                    isEnabled = $false;
                    name = 'Deadlocks';
                },
                @{
                    isEnabled = $false;
                    name = 'Errors';
                },
                @{
                    isEnabled = $false;
                    name = 'QueryStoreRuntimeStatistics';
                },
                @{
                    isEnabled = $false;
                    name = 'QueryStoreWaitStatistics';
                },
                @{
                    isEnabled = $false;
                    name = 'SQLInsights';
                },
                @{
                    isEnabled = $false;
                    name = 'Timeouts';
                }
            );
            metrics = @(
                @{
                    isEnabled = $false;
                    name = 'Basic';
                },
                @{
                    isEnabled = $false;
                    name = 'InstanceAndAppAdvanced';
                },
                @{
                    isEnabled = $false;
                    name = 'WorkloadManagement';
                }
            );
            <#storageAccount = @{
                name = '<Name>';
                resourceGroupName = '<ResourceGroupName>';
                subscriptionId = '<SubscriptionId>;
            };#>
        };
    };
    connectionPolicy = @{ # Optional
        value = 'Default';
    };
    dnsAliases = @{ # Optional
        value = @();
    };
    elasticPools = @{ # Optional
        value = @(
            @{
                isZoneRedundant = $false;
                maximumSizeInBytes = 268435456000;
                name = 'default';
                perDatabaseSettings = @{<#
                    minimumNumberOfCapacityUnits = 0;
                    maximumNumberOfCapacityUnits = 2;
                #>};
                skuName = 'GP_Gen5_2';
            }
        );
    };
    firewallRules = @{ # Optional
        value = @{<#
            inbound = @(
                @{
                    endIpAddress = '<EndIpAddress>';
                    name = '<Name>';
                    startIpAddress = '<StartIpAddress>';
                }
            );
            outbound = @(
                @{
                    fullyQualifiedDomainName = '<FullyQualifiedDomainName>';
                }
            );
        #>};
    };
    identity = @{ # Optional
        value = @{};
    };
    isAllowTrustedMicrosoftServicesEnabled = @{ # Optional
        value = $false;
    };
    isPublicNetworkAccessEnabled = @{ # Optional
        value = $false;
    };
    location = @{ # Required 
        value = 'South Central US';
    };
    name = @{ # Required 
        value = 'byteterracesqltst';
    };
    sqlAdministrator = @{ # Required (if activeDirectoryAdministrator is empty)
        value = @{<#
            name = '<Name>';
            password = '<Password>';
        #>};
    };
    tags = @{ # Optional
        value = @{
            Environment = 'Development';
        };
    };
    virtualNetworkRules = @{ # Optional
        value = @(<#
            @{
                name = '<Name>';
                subnet = @{
                    name = '<Name>';
                    resourceGroupName = '<ResourceGroupName>';
                    subscriptionId = '<SubscriptionId>;
                    virtualNetworkName = '<VirtualNetworkName>';
                };
            }
        #>);
    };
};
$resourceGroupName = 'byteterrace';
$subscriptionNameOrId = 'byteterrace-mpn';
$templatePath = 'C:\ByteTerrace\Source Code\Azure\ResourceManager.Templates\Microsoft.Sql';

az deployment group create `
    --mode $deploymentMode `
    --name $deploymentName `
    --parameters (ConvertTo-Json -Compress -Depth 13 -InputObject $parameters).Replace('"', '\"') `
    --resource-group $resourceGroupName `
    --subscription $subscriptionNameOrId `
    --template-file ('{0}/servers.bicep' -f $templatePath);
```
