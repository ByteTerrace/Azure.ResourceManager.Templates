[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ContainerRegistryName,
    [Parameter(Mandatory = $false)]
    [string[]]$Filter = $null,
    [Parameter(Mandatory = $true)]
    [string]$ModuleDirectoryPath,
    [Parameter(Mandatory = $true)]
    [version]$Tag
);

$basePath = (Get-Item -Path $ModuleDirectoryPath).Name;
$modules = Get-ChildItem `
    -Path "$ModuleDirectoryPath/**/main.bicep" `
    -Recurse |
    Select-Object -Property @(
        @{n='FilePath';e={$_.FullName;};},
        @{n='ModulePath';e={"$($_.Directory.Parent.Name)/$($_.Directory.Name)";};}
    );

if (($null -ne $Filter) -or (0 -lt $Filter.Length)) {
    $modules = $modules | Where-Object { $Filter.Contains($_.ModulePath); };
}

$modules |
    ForEach-Object {
        az bicep publish `
            --force `
            --file ($_.FilePath) `
            --target "br:${ContainerRegistryName}.azurecr.io/${basePath}/$($_.ModulePath):${Tag}";
    };
