# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'StorageAccount-Example';
$location = 'South Central US';
$parameters = @{
    accessTier = @{ # Optional
        value = 'Hot';
    };
    audit = @{ # Optional
        value = @{
            <#logAnalyticsWorkspace = @{
                name = '<Name>';
                resourceGroupName = '<ResourceGroupName>';
                subscriptionId = '<SubscriptionId>;
            };#>
            metrics = @(
                @{
                    isEnabled = $false;
                    name = 'Transaction';
                }
            );
            <#storageAccount = @{
                name = '<Name>';
                resourceGroupName = '<ResourceGroupName>';
                subscriptionId = '<SubscriptionId>;
            };#>
        };
    };
    firewallRules = @{ # Optional
        value = @(<#
            '<IpAddress>'
        #>);
    };
    identity = @{ # Optional
        value = @{};
    };
    isAllowTrustedMicrosoftServicesEnabled = @{ # Optional
        value = $false;
    };
    isDoubleEncryptionAtRestEnabled = @{ # Optional
        value = $true;
    };
    isHttpsOnlyModeEnabled = @{ # Optional
        value = $true;
    };
    isPublicNetworkAccessEnabled = @{ # Optional
        value = $false;
    };
    isSharedKeyAccessEnabled = @{ # Optional
        value = $false;
    };
    kind = @{ # Optional
        value = 'StorageV2';
    };
    location = @{ # Required
        value = 'South Central US';
    };
    name = @{ # Required
        value = 'byteterracebintst';
    };
    sasPolicy = @{ # Optional
        value = @{
            expirationAction = 'Log';
            sasExpirationPeriod = '0.12:00:00';
        };
    };
    services = @{ # Optional
        value = @{
            blob = @{
                audit = @{
                    <#logAnalyticsWorkspace = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                    logs = @(
                        @{
                            isEnabled = $false;
                            name = 'StorageDelete';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageRead';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageWrite';
                        }
                    );
                    metrics = @(
                        @{
                            isEnabled = $false;
                            name = 'Transaction';
                        }
                    );
                    <#storageAccount = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                };
                changeFeed = @{
                    isEnabled = $false;
                    retentionPeriodInDays = 7;
                }
                containers = @{
                    collection = @(
                        @{
                            isNetworkFileSystemV3AllSquashEnabled = $false;
                            isNetworkFileSystemV3RootSquashEnabled = $false;
                            metadata = @{
                                Environment = 'Development';
                            };
                            name = 'tmp';
                            publicAccessLevel = 'None';
                            versioning = @{
                                immutability = @{
                                    isEnabled = $false;
                                    isProtectedAppendWritesEnabled = $false;
                                    retentionPeriodInDays = 3;
                                };
                                isEnabled = $false;
                            };
                        }
                    );
                    softDeletion = @{
                        isEnabled = $true;
                        retentionPeriodInDays = 13;
                    };
                };
                corsRules = @(
                    @{
                        allowedMethods = @('GET');
                        allowedHeaders = @('Content-Type');
                        allowedOrigins = @('https://byteterrace.com');
                        exposedHeaders = @('Content-Type');
                        maxAgeInSeconds = 17;
                    }
                );
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
                isAnonymousAccessEnabled = $false;
                isHierarchicalNamespaceEnabled = $true;
                isNetworkFileSystemV3Enabled = $true;
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
                versioning = @{
                    immutability = @{
                        isEnabled = $false;
                        isProtectedAppendWritesEnabled = $false;
                        retentionPeriodInDays = 3;
                        state = 'Disabled';
                    };
                    isEnabled = $false;
                };
            };
            file = @{
                audit = @{
                    <#logAnalyticsWorkspace = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                    logs = @(
                        @{
                            isEnabled = $false;
                            name = 'StorageDelete';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageRead';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageWrite';
                        }
                    );
                    metrics = @(
                        @{
                            isEnabled = $false;
                            name = 'Transaction';
                        }
                    );
                    <#storageAccount = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                };
                corsRules = @(
                    @{
                        allowedMethods = @('GET');
                        allowedHeaders = @('Content-Type');
                        allowedOrigins = @('https://byteterrace.com');
                        exposedHeaders = @('Content-Type');
                        maxAgeInSeconds = 17;
                    }
                );
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
                    collection = @(
                        @{
                            accessTier = 'Hot';
                            enabledProtocols = 'SMB';
                            metadata = @{
                                Environment = 'Development';
                            };
                            name = 'tmp';
                            quotaInGigabytes = 5;
                            rootSquashMode = 'NoRootSquash';
                        }
                    );
                    isLargeSupportEnabled = $false;
                    softDeletion = @{
                        isEnabled = $true;
                        retentionPeriodInDays = 7;
                    };
                };
            };
            queue = @{
                audit = @{
                    <#logAnalyticsWorkspace = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                    logs = @(
                        @{
                            isEnabled = $false;
                            name = 'StorageDelete';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageRead';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageWrite';
                        }
                    );
                    metrics = @(
                        @{
                            isEnabled = $false;
                            name = 'Transaction';
                        }
                    );
                    <#storageAccount = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                };
                collection = @(
                    @{
                        metadata = @{
                            Environment = 'Development';
                        };
                        name = 'tmp';
                    }
                );
                corsRules = @(
                    @{
                        allowedMethods = @('GET');
                        allowedHeaders = @('Content-Type');
                        allowedOrigins = @('https://byteterrace.com');
                        exposedHeaders = @('Content-Type');
                        maxAgeInSeconds = 17;
                    }
                );
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
            };
            table = @{
                audit = @{
                    <#logAnalyticsWorkspace = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                    logs = @(
                        @{
                            isEnabled = $false;
                            name = 'StorageDelete';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageRead';
                        },
                        @{
                            isEnabled = $false;
                            name = 'StorageWrite';
                        }
                    );
                    metrics = @(
                        @{
                            isEnabled = $false;
                            name = 'Transaction';
                        }
                    );
                    <#storageAccount = @{
                        name = '<Name>';
                        resourceGroupName = '<ResourceGroupName>';
                        subscriptionId = '<SubscriptionId>;
                    };#>
                };
                collection = @(
                    @{
                        name = 'tmp';
                    }
                );
                corsRules = @(
                    @{
                        allowedMethods = @('GET');
                        allowedHeaders = @('Content-Type');
                        allowedOrigins = @('https://byteterrace.com');
                        exposedHeaders = @('Content-Type');
                        maxAgeInSeconds = 17;
                    }
                );
                encryption = @{
                    isEnabled = $true;
                    keyType = 'Account';
                };
            };
        };
    };
    skuName = @{ # Optional
        value = 'Standard_LRS';
    };
    tags = @{ # Optional
        value = @{
            Environment = 'Development';
        };
    };
    virtualNetworkRules = @{ # Optional
        value = @(<#
            @{
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
