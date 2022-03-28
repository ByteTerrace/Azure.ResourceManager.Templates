# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'VirtualWan-Example';
$parameters = @{
    isBranchToBranchTrafficEnabled = @{
        value = $false;
    };
    isVirtualPrivateNetworkEncryptionEnabled = @{
        value = $false;
    };
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracewantst';
    };
    skuName = @{
        value = 'Basic';
    };
    tags = @{
        value = @{
            Environment = 'Development';
        };
    };
};
$resourceGroupName = 'byteterrace';
$subscriptionNameOrId = 'byteterrace-mpn';
$templatePath = 'C:\ByteTerrace\Source Code\Azure\ResourceManager.Templates\Microsoft.Network';

az deployment group create `
    --mode $deploymentMode `
    --name $deploymentName `
    --parameters (ConvertTo-Json -Compress -Depth 13 -InputObject $parameters).Replace('"', '\"') `
    --resource-group $resourceGroupName `
    --subscription $subscriptionNameOrId `
    --template-file ('{0}/virtualWans.bicep' -f $templatePath);
```
