$containerRegistryName = 'tlkcr00000.azurecr.io';

Get-ChildItem -Path './**/*.bicep' |
    ForEach-Object {
        $nameParts = $_.Directory.Name.Split('.');
        $namespaceA = $nameParts[0].ToLowerInvariant();
        $namespaceB = ([Regex]::Replace($nameParts[1], '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());
        $repositoryName = ([Regex]::Replace([IO.Path]::GetFileNameWithoutExtension($_.Name), '(?<=.)(?=[A-Z])', '-').ToLowerInvariant());

        az bicep publish `
            --file $_.FullName `
            --target "br:${containerRegistryName}/azure/bicep/${namespaceA}.${namespaceB}/${repositoryName}:1.0.0";
    };
