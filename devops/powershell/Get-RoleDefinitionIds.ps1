[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
);

class RoleDefinition {
    [string]$id;
    [string]$name;
}

New-Item `
    -Force `
    -ItemType 'File' `
    -Path $TargetPath;

$jsonSerializerOptions = [Text.Json.JsonSerializerOptions]::new();
$roleDefinitions = az role definition list --query 'sort_by([].{ id: name, name: roleName }, &name)';
$roleDefinitionsDictionary = [Collections.Generic.Dictionary[string, string]]::new();

$jsonSerializerOptions.PropertyNamingPolicy = [Text.Json.JsonNamingPolicy]::CamelCase;
$jsonSerializerOptions.WriteIndented = $true;

[Text.Json.JsonSerializer]::Deserialize(
        $roleDefinitions,
        [RoleDefinition[]],
        $jsonSerializerOptions
    ) |
    ForEach-Object {
        $roleDefinitionsDictionary.Add($_.name, $_.id);
    };

Add-Content `
    -Path $TargetPath `
    -Value ([Text.Json.JsonSerializer]::Serialize($roleDefinitionsDictionary, $jsonSerializerOptions));
