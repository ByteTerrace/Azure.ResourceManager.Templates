param(
    [string]$LogFilePath
);

function Disable-NetworkDiscoverability {
    $path = 'HKLM:/SYSTEM/CurrentControlSet/Control/Network';

    if (-not (Test-Path -Path $path)) {
        New-Item `
            -Force `
            -Name 'NewNetworkWindowOff' `
            -Path $path;
    }
}
function Disable-UserAccessControl {
    $path = 'HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Policies/System';

    if (Test-Path -Path $path) {
        Set-ItemProperty `
            -Force `
            -Name 'ConsentPromptBehaviorAdmin' `
            -Path $path `
            -Type 'DWORD' `
            -Value 0;
    }
}
function Enable-DotNetStrongCrypto {
    $path = 'HKLM:/SOFTWARE/Microsoft/.NETFramework/v4.0.30319';

    if (Test-Path -Path $path){
        Set-ItemProperty `
            -Name 'SchUseStrongCrypto' `
            -Path $path `
            -Type 'DWORD' `
            -Value 1;
    }

    $path = 'HKLM:/SOFTWARE/Wow6432Node/Microsoft/.NETFramework/v4.0.30319';

    if (Test-Path -Path $path){
        Set-ItemProperty `
            -Name 'SchUseStrongCrypto' `
            -Path $path `
            -Type 'DWORD' `
            -Value 1;
    }
}
function Enable-LongPathBehavior {
    $path = 'HKLM:/SYSTEM/CurrentControlSet/Control/FileSystem';

    if (Test-Path -Path $path){
        Set-ItemProperty `
            -Name 'LongPathsEnabled' `
            -Path $path `
            -Type 'DWORD' `
            -Value 1;
    }
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
function Install-AmazonWebServicesCli {
    param(
        [string]$LogFilePath
    );

    $installerFileName = 'AWSCLIV2.msi';
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://awscli.amazonaws.com/${installerFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message "Installing Amazon Web Services CLI." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @(
            '/i', "`"${installerFilePath}`"",
            '/norestart',
            '/qn'
        ) `
        -FilePath "msiexec.exe" `
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
function Install-AzureCli {
    param(
        [string]$LogFilePath
    );

    $extensionsPath = ([IO.Path]::Combine(${Env:CommonProgramFiles}, 'AzureCliExtensions'));;
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri 'https://aka.ms/installazurecliwindows' `
        -TargetPath ([IO.Path]::Combine((Get-Location), 'azure-cli.msi'));

    Write-Log `
        -Message "Installing Azure CLI." `
        -Path $LogFilePath;
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $extensionsPath |
        Out-Null;
    [Environment]::SetEnvironmentVariable( `
        'AZURE_EXTENSION_DIR', `
        $extensionsPath, `
        [System.EnvironmentVariableTarget]::Machine `
    );

    $process = Start-Process `
        -ArgumentList @(
            '/i', "`"${installerFilePath}`"",
            '/norestart',
            '/qn'
        ) `
        -FilePath "msiexec.exe" `
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
function Install-GoogleCloudCli {
    param(
        [string]$LogFilePath
    );

    $installerFileName = 'GoogleCloudSDKInstaller.exe';
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://dl.google.com/dl/cloudsdk/channels/rapid/${installerFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message "Installing Google Cloud CLI." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @(
            '/allusers',
            '/noreporting',
            '/S'
        ) `
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
function Install-PowerShell {
    param(
        [string]$LogFilePath,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = (Invoke-WebRequest `
            -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json' `
            -UseBasicParsing |
            ConvertFrom-Json).LTSReleaseTag.Substring(1);
    }

    $installerFileName = "PowerShell-${Version}-win-x64.msi";
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://github.com/PowerShell/PowerShell/releases/download/v${Version}/${installerFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message "Installing PowerShell ${Version}." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @(
            '/i', "`"$installerFilePath`""
            '/quiet'
        ) `
        -FilePath 'msiexec.exe' `
        -PassThru `
        -Wait;

    if (0 -ne $process.ExitCode) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }
}
function Install-WindowsFeatures {
    param (
        [hashtable[]]$Features,
        [string]$LogFilePath
    );

    foreach ($feature in $Features) {
        Write-Log `
            -Message "Installing Windows feature '$($feature.Name)'." `
            -Path $LogFilePath;
        Install-WindowsFeature @feature | Out-Null;
    }
}
function Install-WindowsOptionalFeatures {
    param (
        [string[]]$FeatureNames,
        [string]$LogFilePath
    );

    foreach ($name in $FeatureNames) {
        Write-Log `
            -Message "Enabling Windows optional feature '${name}'." `
            -Path $LogFilePath;
        Enable-WindowsOptionalFeature `
            -FeatureName $name `
            -NoRestart `
            -Online |
            Out-Null;
    }
}
function Resize-SystemDrive {
    param(
        [string]$LogFilePath,
        [long]$MaximumSize
    );

    $driveLetter = ${Env:SystemDrive}[0];

    if (0 -ge $MaximumSize) {
        $MaximumSize = (Get-PartitionSupportedSize -DriveLetter $driveLetter).SizeMax;
    }

    Write-Log `
        -Message "Ensuring that system drive '${driveLetter}' size matches requested size of ${MaximumSize} bytes." `
        -Path $LogFilePath;

    if ($MaximumSize -gt (Get-Partition -DriveLetter $driveLetter).Size) {
        Resize-Partition `
            -DriveLetter $driveLetter `
            -Size $MaximumSize;
    }
}
function Set-WindowsDefenderConfiguration {
    $advancedthreatProtectionKey = 'HKLM:/SOFTWARE/Policies/Microsoft/Windows Advanced Threat Protection'
    $preferences = @{
        DisableArchiveScanning = $true;
        DisableAutoExclusions = $true;
        DisableBehaviorMonitoring = $true;
        DisableBlockAtFirstSeen = $true;
        DisableCatchupFullScan = $true;
        DisableCatchupQuickScan = $true;
        DisableIOAVProtection = $true;
        DisablePrivacyMode = $true;
        DisableRealtimeMonitoring = $true;
        DisableScanningNetworkFiles = $true;
        DisableScriptScanning = $true;
        EnableControlledFolderAccess = 'Disable';
        EnableNetworkProtection = 'Disabled';
        ExclusionPath = @('C:\', 'D:\');
        MAPSReporting = 0;
        PUAProtection = 0;
        ScanAvgCPULoadFactor = 5;
        SignatureDisableUpdateOnStartupWithoutEngine = $true;
        SubmitSamplesConsent = 2;
    };

    Write-Log `
        -Message "Configuring Windows Defender." `
        -Path $LogFilePath;

    Set-MpPreference @preferences | Out-Null;
    Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender\' | Disable-ScheduledTask | Out-Null;

    if (Test-Path -Path $advancedthreatProtectionKey) {
        Set-ItemProperty `
            -Name 'ForceDefenderPassiveMode' `
            -Path $advancedthreatProtectionKey `
            -Type 'DWORD' `
            -Value '1';
    }
}
function Write-Log {
    param(
        [string]$Message,
        [string]$Path
    );

    Add-Content `
        -Path $Path `
        -Value "[Install-DevOpsAgentSoftware0.ps1@$(Get-TimeMarker)] - ${Message}";
}

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'C:/WindowsAzure/ByteTerrace/main.log';
    }

    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;';
    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;';
    Disable-NetworkDiscoverability;
    Disable-UserAccessControl;
    Get-ScheduledTask `
        -TaskName 'ServerManager' |
        Disable-ScheduledTask |
        Out-Null;
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::GetDirectoryName($LogFilePath)) |
        Out-Null;
    Resize-SystemDrive `
        -LogFilePath $LogFilePath `
        -MaximumSize 0;
    Set-WindowsDefenderConfiguration -LogFilePath $LogFilePath;
    Install-WindowsFeatures `
        -Features @(
            @{
                Name = 'Containers';
            },
            @{
                IncludeAllSubFeature = $true;
                Name = 'Hyper-V';
            },
            @{
                IncludeAllSubFeature = $true;
                Name = 'NET-Framework-45-Features';
            }
        ) `
        -LogFilePath $LogFilePath;
    Install-WindowsOptionalFeatures `
        -FeatureNames @(
            'HypervisorPlatform',
            'Microsoft-Windows-Subsystem-Linux',
            'VirtualMachinePlatform'
        ) `
        -LogFilePath $LogFilePath;
    Enable-DotNetStrongCrypto;
    Install-PowerShell `
        -LogFilePath $LogFilePath `
        -Version 'latest';
    Install-AmazonWebServicesCli -LogFilePath $LogFilePath;
    Install-AzureCli -LogFilePath $LogFilePath;
    Install-GoogleCloudCli -LogFilePath $LogFilePath;
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
