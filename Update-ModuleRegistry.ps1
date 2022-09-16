param(
    [Parameter(Mandatory = $true)]
    [string]$ContainerRegistryName,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionNameOrId
)

az ts create `
    --name 'microsoft.authorization_role-assignments' `
    --resource-group 'thelankrew' `
    --subscription 'byteterrace-mpn' `
    --template-file './Microsoft.Authorization/roleAssignments.json' `
    --version '1.0.0' `
    --yes |
    Out-Null;

Get-ChildItem -Path './**/*.bicep' |
    ForEach-Object {
        $nameParts = $_.Directory.Name.Split('.');
        $namespaceA = $nameParts[0].ToLowerInvariant();
        $namespaceB = ([Regex]::Replace($nameParts[1], '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());
        $repositoryName = ([Regex]::Replace([IO.Path]::GetFileNameWithoutExtension($_.Name), '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());

        az bicep publish `
            --file $_.FullName `
            --target "br:${ContainerRegistryName}/azure/bicep/${namespaceA}.${namespaceB}/${repositoryName}:1.0.0";
    };

az bicep publish `
    --file './resourceGroupDeployment.bicep' `
    --target "br:${ContainerRegistryName}/azure/bicep/resource-group-deployment:1.0.0" |
    Out-Null;

az ts create `
    --name 'resource-group-deployment' `
    --resource-group $ResourceGroupName `
    --subscription $SubscriptionNameOrId `
    --template-file './resourceGroupDeployment.bicep' `
    --version '1.0.0' `
    --yes |
    Out-Null;
