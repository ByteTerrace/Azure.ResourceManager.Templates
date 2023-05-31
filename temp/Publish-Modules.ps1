[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ContainerRegistryName,
    [Parameter(Mandatory = $true)]
    [string]$ModuleDirectoryPath,
    [Parameter(Mandatory = $true)]
    [version]$Tag
);

Get-ChildItem `
    -Path "$ModuleDirectoryPath/**/main.bicep" `
    -Recurse |
    ForEach-Object {
        $file = $_;
        $repositoryPath = "$((Get-Item -Path $ModuleDirectoryPath).Name)/$($file.Directory.Parent.Name)/$($file.Directory.Name)";
        $target = "br:${ContainerRegistryName}.azurecr.io/${repositoryPath}:${Tag}";

        az bicep publish `
            --file $file `
            --target $target;
    };
