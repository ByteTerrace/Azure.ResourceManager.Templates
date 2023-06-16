[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Filter = $null,
    [Parameter(Mandatory = $true)]
    [version]$Version
);

$basePath = (Get-Item -Path "$PSScriptRoot/../../microsoft");
$jsonDocumentOptions = [Text.Json.JsonDocumentOptions]::new();
$jsonDocumentOptions.CommentHandling = [Text.Json.JsonCommentHandling]::Skip;
$modules = Get-ChildItem `
    -Path "$($basePath.FullName)/**/main.bicep" `
    -Recurse |
    Select-Object -Property @(
        @{n='FilePath';e={$_.FullName;};},
        @{n='ModulePath';e={"$($_.Directory.Parent.Name)/$($_.Directory.Name)";};}
    );
$registryName = [Text.Json.JsonDocument]::Parse(
        (Get-Content -Path "$PSScriptRoot/../../bicepconfig.json"),
        $jsonDocumentOptions
    ).
    RootElement.
    GetProperty('moduleAliases').
    GetProperty('br').
    GetProperty('bytrc').
    GetProperty('registry').
    GetString().
    Replace('.azurecr.io', '');

if (($null -ne $Filter) -or (0 -lt $Filter.Length)) {
    $modules = $modules | Where-Object { $Filter.Contains($_.ModulePath); };
}

$modules | ForEach-Object `
    -Parallel {
        $basePath = $using:basePath;
        $registryName = $using:registryName;
        $tag = $using:Version;
        $target = "br:${registryName}.azurecr.io/$($basePath.Name)/$($_.ModulePath):${tag}";

        Write-Host "Publishing ${target}...";

        bicep publish `
            ($_.FilePath) `
            --force `
            --target $target;
    } `
    -ThrottleLimit 7;
