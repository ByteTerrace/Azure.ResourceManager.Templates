$containerRegistryName = 'tlkcr00000.azurecr.io';

Get-ChildItem -Path './**/*.bicep' |
    ForEach-Object {
        $directoryName = $_.Directory.Name.ToLowerInvariant();
        $repositoryName = ([Regex]::Replace([IO.Path]::GetFileNameWithoutExtension($_.Name), '(?<=.)(?=[A-Z])', '-').ToLower());

        az bicep publish `
            --file $_.FullName `
            --target "br:${containerRegistryName}/azure/bicep/${directoryName}/${repositoryName}:1.0.0";
    };
