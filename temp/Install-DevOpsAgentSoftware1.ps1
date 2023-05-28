param(
    [string]$LogFilePath
);

function Get-AzureAccessToken {
    param(
        [string]$ClientId,
        [string]$LogFilePath,
        [string]$ResourceUri
    );

    $uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-12-13&resource=${ResourceUri}";

    if (-not ([string]::IsNullOrEmpty($ClientId))) {
        $uri += "&client_id=${ClientId}";
    }

    return (Invoke-WebRequest `
        -Headers @{ Metadata = 'true'; } `
        -Uri $uri `
        -UseBasicParsing |
        ConvertFrom-Json).access_token;
}
function Get-AzureStorageBlob {
    param (
        [string]$AccountName,
        [string]$BlobPath,
        [string]$ClientId,
        [string]$ContainerName,
        [string]$LogFilePath,
        [string]$TargetPath
    );

    $accessToken = Get-AzureAccessToken `
        -ClientId $ClientId `
        -LogFilePath $LogFilePath `
        -ResourceUri 'https://storage.azure.com';

    return Get-File `
        -Headers @{
            Authorization = "Bearer ${accessToken}";
            'x-ms-version' = '2022-11-02';
        } `
        -LogFilePath $LogFilePath `
        -SourceUri "https://${AccountName}.blob.core.windows.net/${ContainerName}/${BlobPath}" `
        -TargetPath $TargetPath;
}
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
function Install-VisualStudioExtension {
    param(
        [string]$Name,
        [string]$Publisher,
        [string]$Version
    );

    $extensionFilePath = Get-File `
        -SourceUri "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${Publisher}/vsextensions/${Name}/${Version}/vspackage" `
        -TargetPath ([IO.Path]::Combine((Get-Location), "${Name}.vsix"));
    $visualStudioBasePath = $null;

    try {
        $visualStudioBasePath = (& "${Env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -property installationPath);
    }
    catch [Management.Automation.CommandNotFoundException] {
        throw 'Unable to find ''vswhere.exe''; Visual Studio must be installed before running this script.';
    }

    $process = Start-Process `
        -ArgumentList @(
            '/quiet',
            "`"${extensionFilePath}`""
        ) `
        -FilePath "${visualStudioBasePath}/Common7/IDE/VSIXInstaller.exe" `
        -PassThru `
        -Wait;

    if ((0 -ne $process.ExitCode) -and (1001 -ne $process.ExitCode)) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $extensionFilePath) {
        Remove-Item `
            -Force `
            -Path $extensionFilePath;
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
    $global:ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $global:ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'C:/WindowsAzure/ByteTerrace/main.log';
    }

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

    <#$visualStudioExtensions = @(
        @{
            Name = 'MicrosoftAnalysisServicesModelingProjects2022';
            Publisher = 'ProBITools';
            Version = '3.0.10';
        },
        @{
            Name = 'MicrosoftReportProjectsforVisualStudio2022';
            Publisher = 'ProBITools';
            Version = '3.0.7';
        },
        @{
            Name = 'MicrosoftVisualStudio2022InstallerProjects';
            Publisher = 'VisualStudioClient';
            Version = '2.0.0';
        },
        @{
            Name = 'WixToolsetVisualStudio2022Extension';
            Publisher = 'WixToolset';
            Version = '1.0.0.22';
        }
    );

    $visualStudioExtensions | ForEach-Object {
        $extension = $_;

        Install-VisualStudioExtension `
            -Name $extension.Name `
            -Publisher $extension.Publisher `
            -Version $extension.Version;
    };#>

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
