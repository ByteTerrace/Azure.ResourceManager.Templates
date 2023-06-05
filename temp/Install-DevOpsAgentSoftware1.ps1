[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
);

function Get-File {
    param(
        [hashtable]$Headers,
        [string]$LogFilePath,
        [string]$SourceUri,
        [string]$TargetPath
    );

    $webClient = $null;

    try {
        Write-Log `
            -Message "Downloading file from '${SourceUri}' to '${TargetPath}'." `
            -Path $LogFilePath;

        $webClient = [Net.WebClient]::new();

        if ($null -ne $Headers) {
            foreach ($header in $Headers.GetEnumerator()) {
                $webClient.Headers.Add($header.Key, $header.Value);
            }
        }

        $webClient.DownloadFile($SourceUri, $TargetPath);

        return $TargetPath;
    }
    finally {
        if ($null -ne $webClient) {
            $webClient.Dispose();
        }
    }

    return $null;
}
function Get-TimeMarker {
    return Get-Date -Format 'yyyyMMddTHH:mm:ssK';
}
function Install-VisualStudio {
    param(
        [string[]]$Components,
        [string]$Edition,
        [string]$LogFilePath,
        [string]$Version
    );

    $bootstrapperArgumentList = @(
        '--addProductLang', 'en-US',
        '--includeRecommended',
        '--nickname', 'DevOps',
        '--norestart',
        '--quiet'
    );
    $bootstrapperFileName = "vs_${Edition}.exe";
    $bootstrapperFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://aka.ms/vs/${Version}/release/${bootstrapperFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $bootstrapperFileName));

    $Components | ForEach-Object {
        $bootstrapperArgumentList += '--add';
        $bootstrapperArgumentList += $_;
    }

    Write-Log `
        -Message "Installing Visual Studio ${Edition}." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList $bootstrapperArgumentList `
        -FilePath $bootstrapperFilePath `
        -PassThru `
        -Wait;

    if ((0 -ne $process.ExitCode) -and (3010 -ne $process.ExitCode)) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $bootstrapperFilePath) {
        Remove-Item `
            -Force `
            -Path $bootstrapperFilePath;
    }
}
function Write-Log {
    param(
        [string]$Message,
        [string]$Path
    );

    Add-Content `
        -Path $Path `
        -Value "[Install-DevOpsAgentSoftware1.ps1@$(Get-TimeMarker)] - ${Message}";
}

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;
    [Net.ServicePointManager]::SecurityProtocol = (
        [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls13
    );

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
        -LogFilePath $LogFilePath `
        -Version '17';
    Write-Log `
        -Message 'Complete!' `
        -Path $LogFilePath;
}
catch {
    Write-Log `
        -Message $_ `
        -Path $LogFilePath;
    Write-Log `
        -Message 'Failed!' `
        -Path $LogFilePath;

    throw;
}
