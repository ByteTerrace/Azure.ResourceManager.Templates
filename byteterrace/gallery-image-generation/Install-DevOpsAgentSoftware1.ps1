[CmdletBinding()]
param();

function Add-BillOfMaterialsEntry {
    param(
        [string]$Name,
        [string]$Publisher,
        [string]$SourceUri,
        [string]$ValidationScript,
        [string]$Version
    );

    $rs = [char]::ConvertFromUtf32(30);

    Add-Content `
        -Path ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'BillOfMaterials.log')) `
        -Value "${Name}${rs}${Publisher}${rs}${SourceUri}${rs}${ValidationScript}${rs}${Version}";
}
function Get-File {
    param(
        [hashtable]$Headers,
        [string]$SourceUri,
        [string]$TargetFileName
    );

    $webClient = $null;

    try {
        $targetPath = ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $TargetFileName));
        $webClient = [Net.WebClient]::new();

        if ($null -ne $Headers) {
            foreach ($header in $Headers.GetEnumerator()) {
                $webClient.Headers.Add($header.Key, $header.Value);
            }
        }

        $webClient.DownloadFile($SourceUri, $targetPath);

        return $targetPath;
    }
    finally {
        if ($null -ne $webClient) {
            $webClient.Dispose();
        }
    }

    return $null;
}
function Install-VisualStudio {
    param(
        [string[]]$Components,
        [string]$Edition,
        [string]$Version
    );

    $sourceFileName = "vs_${Edition}.exe";
    $sourceUri = "https://aka.ms/vs/${Version}/release/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -Name "Visual Studio ${Edition}" `
        -Publisher 'Microsoft' `
        -SourceUri $sourceUri `
        -ValidationScript '([version](& "${Env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -property catalog_productDisplayVersion)).Major;' `
        -Version $Version;

    $installerArgumentList = @(
            '--addProductLang', 'en-US',
            '--includeRecommended',
            '--nickname', 'DevOps',
            '--norestart',
            '--quiet'
        );
    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetFileName $sourceFileName;

    $Components | ForEach-Object {
        $installerArgumentList += '--add';
        $installerArgumentList += $_;
    }

    $process = Start-Process `
        -ArgumentList $installerArgumentList `
        -FilePath $installerFilePath `
        -PassThru `
        -Wait;

    if ((0 -ne $process.ExitCode) -and (3010 -ne $process.ExitCode)) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }
}

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;
[Net.ServicePointManager]::SecurityProtocol = (
        [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls13
    );

Set-StrictMode -Version 'Latest';
Add-Content `
    -Path ($profile.AllUsersAllHosts) `
    -Value '$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;';
Add-Content `
    -Path ($profile.AllUsersAllHosts) `
    -Value '$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;';
Install-VisualStudio `
    -Components @(
        'Component.Dotfuscator',
        'Microsoft.Component.Azure.DataLake.Tools',
        'Microsoft.Net.Component.4.5.2.TargetingPack',
        'Microsoft.Net.Component.4.6.TargetingPack',
        'Microsoft.Net.Component.4.6.1.TargetingPack',
        'Microsoft.Net.Component.4.6.2.TargetingPack',
        'Microsoft.Net.Component.4.7.TargetingPack',
        'Microsoft.Net.Component.4.7.1.TargetingPack',
        'Microsoft.Net.Component.4.7.2.TargetingPack',
        'Microsoft.Net.Component.4.8.TargetingPack',
        'Microsoft.Net.Component.4.8.1.SDK',
        'Microsoft.Net.Component.4.8.1.TargetingPack',
        'Microsoft.VisualStudio.Component.AspNet',
        'Microsoft.VisualStudio.Component.AspNet45',
        'Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools',
        'Microsoft.VisualStudio.Component.AzureDevOps.OfficeIntegration',
        'Microsoft.VisualStudio.Component.Debugger.JustInTime',
        'Microsoft.VisualStudio.Component.DotNetModelBuilder',
        'Microsoft.VisualStudio.Component.DslTools',
        'Microsoft.VisualStudio.Component.EntityFramework',
        'Microsoft.VisualStudio.Component.LinqToSql',
        'Microsoft.VisualStudio.Component.PortableLibrary',
        'Microsoft.VisualStudio.Component.SecurityIssueAnalysis',
        'Microsoft.VisualStudio.Component.Sharepoint.Tools',
        'Microsoft.VisualStudio.Component.SQL.SSDT',
        'Microsoft.VisualStudio.Component.WebDeploy',
        'Microsoft.VisualStudio.Component.Windows10SDK.20348',
        'Microsoft.VisualStudio.Component.Windows11SDK.22621',
        'Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices',
        'Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools',
        'Microsoft.VisualStudio.ComponentGroup.Web.CloudTools',
        'Microsoft.VisualStudio.Workload.Azure',
        'Microsoft.VisualStudio.Workload.Data',
        'Microsoft.VisualStudio.Workload.DataScience',
        'Microsoft.VisualStudio.Workload.ManagedDesktop',
        'Microsoft.VisualStudio.Workload.NativeCrossPlat',
        'Microsoft.VisualStudio.Workload.NativeDesktop',
        'Microsoft.VisualStudio.Workload.NativeMobile',
        'Microsoft.VisualStudio.Workload.NetCrossPlat',
        'Microsoft.VisualStudio.Workload.NetWeb',
        'Microsoft.VisualStudio.Workload.Node',
        'Microsoft.VisualStudio.Workload.Office',
        'Microsoft.VisualStudio.Workload.Python',
        'Microsoft.VisualStudio.Workload.Universal',
        'Microsoft.VisualStudio.Workload.VisualStudioExtension',
        'wasm.tools'
    ) `
    -Edition 'Enterprise' `
    -Version '17';
