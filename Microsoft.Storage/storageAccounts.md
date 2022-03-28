# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'StorageAccount-Example';
$location = 'South Central US';
$parameters = @{
    accessTier = @{
        value = 'Hot';
    };
    firewallRules = @{
        value = @();
    };
    identity = @{
        value = @{};
    };
    isAllowTrustedMicrosoftServicesEnabled = @{
        value = $false;
    };
    isDoubleEncryptionAtRestEnabled = @{
        value = $true;
    };
    isHttpsOnlyModeEnabled = @{
        value = $true;
    };
    isPublicNetworkAccessEnabled = @{
        value = $false;
    };
    isSharedKeyAccessEnabled = @{
        value = $false;
    };
    kind = @{
        value = 'StorageV2';
    };
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracebintst';
    };
    sasPolicy = @{
        value = @{
            expirationAction = 'Log';
            sasExpirationPeriod = '0.12:00:00';
        };
    };
    services = @{
        value = @{
            blob = @{
                changeFeed = @{
                    isEnabled = $false;
                    retentionPeriodInDays = 7;
                }
                containers = @{
                    collection = @(
                        @{
                            name = 'tmp';
                        }
                    );
                    softDeletion = @{
                        isEnabled = $true;
                        retentionPeriodInDays = 13;
                    };
                };
                corsRules = @();
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
                isAnonymousAccessEnabled = $false;
                isHierarchicalNamespaceEnabled = $true;
                isNetworkFileSystemV3Enabled = $true;
                isVersioningEnabled = $false;
                pointInTimeRestoration = @{
                    isEnabled = $false;
                    retentionPeriodInDays = 3;
                };
                sftp = @{
                    isEnabled = $false;
                    isLocalUserAccessEnabled = $false;
                };
                softDeletion = @{
                    isEnabled = $true;
                    retentionPeriodInDays = 13;
                };
            };
            file = @{
                corsRules = @();
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
                serverMessageBlock = @{
                    authenticationMethods = 'Kerberos;';
                    channelEncryption = 'AES-256-GCM;';
                    kerberosTicketEncryption = 'AES-256;';
                    versions = 'SMB3.1.1;';
                };
                shares = @{
                    collection = @();
                    isLargeSupportEnabled = $false;
                    softDeletion = @{
                        isEnabled = $true;
                        retentionPeriodInDays = 7;
                    };
                };
            };
            queue = @{
                corsRules = @();
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
            };
            table = @{
                corsRules = @();
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
            };
        };
    };
    skuName = @{
        value = 'Standard_LRS';
    };
    tags = @{
        value = @{
            Environment = 'Development';
        };
    };
    virtualNetworkRules = @{
        value = @();
    };
};
$resourceGroupName = 'byteterrace'
$subscriptionNameOrId = 'byteterrace-mpn'
$tags = '{\"Environment\":\"Development\"}';
$templatePath = 'C:\ByteTerrace\Source Code\Azure\ResourceManager.Templates\Microsoft.Storage';

az deployment group create `
    --mode $deploymentMode `
    --name $deploymentName `
    --parameters (ConvertTo-Json -Compress -Depth 13 -InputObject $parameters).Replace('"', '\"') `
    --resource-group $resourceGroupName `
    --subscription $subscriptionNameOrId `
    --template-file ('{0}/storageAccounts.bicep' -f $templatePath);
```
