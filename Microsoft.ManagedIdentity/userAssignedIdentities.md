# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'ManagedIdentity-Example';
$parameters = @{
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracemitst';
    };
    tags = @{
        value = @{
            Environment = 'Development';
        };
    };
};
$resourceGroupName = 'byteterrace';
$subscriptionNameOrId = 'byteterrace-mpn';
$templatePath = 'C:\ByteTerrace\Source Code\Azure\ResourceManager.Templates\Microsoft.ManagedIdentity';

az deployment group create `
    --mode $deploymentMode `
    --name $deploymentName `
    --parameters (ConvertTo-Json -Compress -Depth 13 -InputObject $parameters).Replace('"', '\"') `
    --resource-group $resourceGroupName `
    --subscription $subscriptionNameOrId `
    --template-file ('{0}/userAssignedIdentities.bicep' -f $templatePath);
```
