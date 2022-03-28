# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'ContainerRegistry-Example';
$parameters = @{
    identity = @{
        value = @{};
    };
    isAdministratorAccountEnabled = @{
        value = $false;
    };
    isAllowTrustedMicrosoftServicesEnabled = @{
        value = $false;
    };
    isAnonymousPullEnabled = @{
        value = $false;
    };
    isDedicatedDataEndpointEnabled = @{
        value = $false;
    };
    isPublicNetworkAccessEnabled = @{
        value = $true;
    };
    isZoneRedundant = @{
        value = $false;
    };
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracecrtst';
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
$templatePath = 'C:\ByteTerrace\Source Code\Azure\ResourceManager.Templates\Microsoft.ContainerRegistry';

az deployment group create `
    --mode $deploymentMode `
    --name $deploymentName `
    --parameters (ConvertTo-Json -Compress -Depth 13 -InputObject $parameters).Replace('"', '\"') `
    --resource-group $resourceGroupName `
    --subscription $subscriptionNameOrId `
    --template-file ('{0}/registries.bicep' -f $templatePath);
```
