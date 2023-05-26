param(
    [string]$LogFilePath
);

function Get-TimeMarker {
    return Get-Date -Format "yyyyMMddTHH:mm:ssK";
}
function Install-VisualStudio {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Components,
        [Parameter(Mandatory = $false)]
        [string]$Edition = 'Enterprise',
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,
        [Parameter(Mandatory = $false)]
        [string]$Version = '17'
    );

    $bootstrapperFileName = "vs_${Edition}.exe";
    $bootstrapperFilePath = [IO.Path]::Combine((Get-Location), $bootstrapperFileName);
    $webClient = $null;

    try {
        $webClient = [Net.WebClient]::new();
        $webClient.DownloadFile("https://aka.ms/vs/${Version}/release/${bootstrapperFileName}", $bootstrapperFilePath);
    }
    finally {
        $webClient.Dispose();
    }

    $argumentList = @(
        '--addProductLang', 'en-US',
        '--includeRecommended',
        '--nickname', 'DevOps',
        '--norestart',
        '--quiet'
    );

    $Components | ForEach-Object {
        $argumentList += '--add';
        $argumentList += $_;
    }

    $process = Start-Process `
        -ArgumentList $argumentList `
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
function Resize-SystemDrive {
    $systemDriveLetter = ${Env:SystemDrive}[0];
    $systemDriveMaximumSize = (Get-PartitionSupportedSize -DriveLetter $systemDriveLetter).SizeMax;

    if ($systemDriveMaximumSize -gt (Get-Partition -DriveLetter $systemDriveLetter).Size) {
        Resize-Partition `
            -DriveLetter $systemDriveLetter `
            -Size $systemDriveMaximumSize;
    }
}
function Write-Log {
    param(
        [string]$LogFilePath,
        [string]$Message
    );

    Add-Content `
        -Path $LogFilePath `
        -Value "[$([IO.Path]::GetFileName($PSCommandPath))@$(Get-TimeMarker)] - ${Message}";
}

Resize-SystemDrive;
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
    -LogFilePath $LogFilePath;
