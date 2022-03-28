# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'VirtualNetwork-Example';
$parameters = @{
    addressPrefixes = @{
        value = @('10.0.0.0/8');
    };
    ddosProtectionPlan = @{
        value = @{};
    };
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracevnettst';
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
    --template-file ('{0}/virtualNetworks.bicep' -f $templatePath);
```
