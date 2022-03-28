# Deploy via Azure CLI & PowerShell
```
$deploymentMode = 'Incremental';
$deploymentName = 'NetworkSecurityGroup-Example';
$parameters = @{
    location = @{
        value = 'South Central US';
    };
    name = @{
        value = 'byteterracensgtst';
    };
    securityRules = @{
        value = @(
            @{
                access = 'Deny';
                description = 'Denies inbound SSH access.';
                destination = @{
                    addressPrefixes = @('10.0.0.0/8');
                    ports = @(22);
                };
                direction = 'Inbound';
                name = 'Deny-Ssh-Inbound';
                priority = 4096;
                protocol = 'TCP';
                source = @{
                    addressPrefixes = @('10.0.0.0/8');
                    ports = @('*');
                };
            };
        );
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
    --template-file ('{0}/networkSecurityGroups.bicep' -f $templatePath);
```
