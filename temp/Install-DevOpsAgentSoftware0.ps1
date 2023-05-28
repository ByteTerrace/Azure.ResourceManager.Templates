param(
    [string]$LogFilePath
);

function Get-TimeMarker {
    return Get-Date -Format 'yyyyMMddTHH:mm:ssK';
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
    $advancedthreatProtectionKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection'
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
    $global:ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $global:ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'C:/WindowsAzure/ByteTerrace/main.log';
    }

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
