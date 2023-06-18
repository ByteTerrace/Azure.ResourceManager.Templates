$rs = [char]::ConvertFromUtf32(30);

(Get-Content -Path "${Env:AGENT_TOOLSDIRECTORY}/BillOfMaterials.log").
    Split([Environment]::NewLine) |
    ForEach-Object {
        $fields = $_.Split($rs);
        $runtimeVersion = (Invoke-Expression -Command $fields[3]);
        $scriptVersion = $fields[4];

        if (-not (('latest' -eq $scriptVersion) -or ($scriptVersion -eq $runtimeVersion))) {
            # TODO: Handle failure case somehow...
        }
    };
