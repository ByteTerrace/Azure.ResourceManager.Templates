param(
    [Parameter(Mandatory = $true)]
    [string]$ContainerRegistryName,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionNameOrId
)

$roleAssignmentsTypeName = 'microsoft.authorization_role-assignments';
$roleAssignmentsVersion = ([version](az ts list `
    --name $roleAssignmentsTypeName `
    --resource-group $ResourceGroupName `
    --subscription $SubscriptionNameOrId `
    --query 'reverse(sort_by([], &name))[0].name' 2>$null |
    ConvertFrom-Json));

if ([string]::IsNullOrEmpty($roleAssignmentsVersion)) {
    $roleAssignmentsVersion = ([Version]'1.0.0');
}

az ts create `
    --name $roleAssignmentsTypeName `
    --resource-group $ResourceGroupName `
    --subscription $SubscriptionNameOrId `
    --template-file './Microsoft.Authorization/roleAssignments.json' `
    --version $roleAssignmentsVersion `
    --yes |
    Out-Null;

Get-ChildItem -Path './**/*.bicep' |
    ForEach-Object {
        $nameParts = $_.Directory.Name.Split('.');
        $namespaceA = $nameParts[0].ToLowerInvariant();
        $namespaceB = ([Regex]::Replace($nameParts[1], '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());
        $repositoryName = ([Regex]::Replace([IO.Path]::GetFileNameWithoutExtension($_.Name), '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());
        $repositoryPath = "azure/bicep/${namespaceA}.${namespaceB}/${repositoryName}";
        $repositoryVersion = ([version](az acr repository show-tags `
            --name ${ContainerRegistryName} `
            --repository $repositoryPath `
            --query '[] | sort(@) | reverse(@)[0]' 2>$null |
            ConvertFrom-Json));

        if ([string]::IsNullOrEmpty($repositoryVersion)) {
            $repositoryVersion = ([Version]'1.0.0');
        }

        $target = "br:${ContainerRegistryName}.azurecr.io/${repositoryPath}:${repositoryVersion}";

        Write-Host "Publishing ${target}...";

        az bicep publish `
            --file $_.FullName `
            --target "br:${ContainerRegistryName}.azurecr.io/${repositoryPath}:${repositoryVersion}";
    };

$resourceGroupDeploymentBicepFilePath = './resourceGroupDeployment.bicep';
$resourceGroupDeploymentTypeName = 'resource-group-deployment';
$resourceGroupDeploymentVersion = ([version](az ts list `
    --name $resourceGroupDeploymentTypeName `
    --resource-group $ResourceGroupName `
    --subscription $SubscriptionNameOrId `
    --query 'reverse(sort_by([], &name))[0].name' 2>$null |
    ConvertFrom-Json));

if ([string]::IsNullOrEmpty($resourceGroupDeploymentVersion)) {
    $resourceGroupDeploymentVersion = ([Version]'1.0.0');
}

$target = "br:${ContainerRegistryName}.azurecr.io/azure/bicep/${resourceGroupDeploymentTypeName}:${resourceGroupDeploymentVersion}";

Write-Host "Publishing ${target}...";

az bicep publish `
    --file $resourceGroupDeploymentBicepFilePath `
    --target $target |
    Out-Null;

az ts create `
    --name $resourceGroupDeploymentTypeName `
    --resource-group $ResourceGroupName `
    --subscription $SubscriptionNameOrId `
    --template-file $resourceGroupDeploymentBicepFilePath `
    --version $resourceGroupDeploymentVersion `
    --yes |
    Out-Null;
