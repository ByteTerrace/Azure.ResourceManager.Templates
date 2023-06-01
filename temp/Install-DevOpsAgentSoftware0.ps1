param(
    [string]$AgentToolsDirectoryPath,
    [string]$LogFilePath
);

function Disable-Debuggers {
    New-ItemProperty `
        -Force `
        -Name 'Debugger' `
        -Path 'HKLM:/SOFTWARE/Microsoft/Windows NT/CurrentVersion/AeDebug' `
        -Type 'String' `
        -Value '-' |
        Out-Null;
    New-ItemProperty `
        -Force `
        -Name 'Debugger' `
        -Path 'HKLM:/SOFTWARE/WOW6432Node/Microsoft/Windows NT/CurrentVersion/AeDebug' `
        -Type 'String' `
        -Value '-' |
        Out-Null;
    New-ItemProperty `
        -Force `
        -Name 'DbgManagedDebugger' `
        -Path "HKLM:/SOFTWARE/Microsoft/.NETFramework" `
        -Type 'String' `
        -Value '-' |
        Out-Null;
    New-ItemProperty `
        -Force `
        -Name 'DbgManagedDebugger' `
        -Path "HKLM:/SOFTWARE/WOW6432Node/Microsoft/.NETFramework" `
        -Type 'String' `
        -Value '-' |
        Out-Null;
}
function Disable-NetworkDiscoverabilityPopup {
    New-Item `
        -Force `
        -Name 'NewNetworkWindowOff' `
        -Path 'HKLM:/SYSTEM/CurrentControlSet/Control/Network' |
        Out-Null;
}
function Disable-ServerManagerPopup {
    Get-ScheduledTask `
        -TaskName 'ServerManager' |
        Disable-ScheduledTask |
        Out-Null;
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
function Enable-RootHypervisorScheduler {
    # https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-scheduler-types#the-root-scheduler

    bcdedit.exe /set hypervisorschedulertype root | Out-Null;
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
        -Message 'Installing Azure CLI.' `
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
function Install-GitHubCli {
    param(
        [string]$LogFilePath
    );

    $installerFileName = 'GitHubCli_Windows_Amd64.msi';
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri ((Invoke-RestMethod `
            -Method 'GET' `
            -Uri 'https://api.github.com/repos/cli/cli/releases/latest' `
            -UseBasicParsing).assets.browser_download_url -match 'windows_amd64.msi' |
            Select-Object -First 1) `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message 'Installing GitHub CLI.' `
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
        -Message 'Installing Google Cloud CLI.' `
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
function Install-NuGetPackageProvider {
    param(
        [string]$LogFilePath
    );

    Write-Log `
        -Message 'Installing NuGet package provider.' `
        -Path $LogFilePath;

    Install-PackageProvider `
        -Force `
        -MinimumVersion '2.8.5.208' `
        -Name 'NuGet' |
        Out-Null;
    Set-PSRepository `
        -InstallationPolicy 'Trusted' `
        -Name 'PSGallery';
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
function Install-7Zip {
    param(
        [string]$LogFilePath,
        [string]$Version
    );

    $installerFileName = "7z$($Version.Replace('.', ''))-x64.exe";
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://www.7-zip.org/a/${installerFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message "Installing 7-Zip ${Version}." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @( '/S' ) `
        -FilePath $installerFilePath `
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
    param(
        [string]$LogFilePath
    );

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
function Set-WindowsErrorReportingConfiguration {
    param(
        [string]$LogFilePath
    );

    Write-Log `
        -Message "Configuring Windows Error Reporting." `
        -Path $LogFilePath;

    New-ItemProperty `
        -Force `
        -Name 'DontShowUI' `
        -Path 'HKLM:/SOFTWARE/Microsoft/Windows/Windows Error Reporting' `
        -Type 'DWORD' `
        -Value 1 |
        Out-Null;
    New-ItemProperty `
        -Force `
        -Name 'ForceQueue' `
        -Path 'HKLM:/SOFTWARE/Microsoft/Windows/Windows Error Reporting' `
        -Type 'DWORD' `
        -Value 1 |
        Out-Null;
    New-ItemProperty `
        -Force `
        -Name 'DefaultConsent' `
        -Path 'HKLM:/SOFTWARE/Microsoft/Windows/Windows Error Reporting/Consent' `
        -Type 'DWORD' `
        -Value 1 |
        Out-Null;
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
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $AgentToolsDirectoryPath |
        Out-Null;
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::GetDirectoryName($LogFilePath)) |
        Out-Null;
    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;';
    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;';
    [Environment]::SetEnvironmentVariable( `
        'AGENT_TOOLSDIRECTORY', `
        ((Get-Item -Path $AgentToolsDirectoryPath).FullName), `
        [System.EnvironmentVariableTarget]::Machine `
    );
    Disable-Debuggers;
    Disable-NetworkDiscoverabilityPopup;
    Disable-ServerManagerPopup;
    Disable-UserAccessControl;
    Enable-LongPathBehavior;
    Enable-RootHypervisorScheduler;
    Set-WindowsDefenderConfiguration -LogFilePath $LogFilePath;
    Set-WindowsErrorReportingConfiguration -LogFilePath $LogFilePath;
    Resize-SystemDrive `
        -LogFilePath $LogFilePath `
        -MaximumSize 0;
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
            'Client-ProjFS',
            'HypervisorPlatform',
            'Microsoft-Windows-Subsystem-Linux',
            'VirtualMachinePlatform'
        ) `
        -LogFilePath $LogFilePath;
    Enable-DotNetStrongCrypto;
    Install-AmazonWebServicesCli -LogFilePath $LogFilePath;
    Install-AzureCli -LogFilePath $LogFilePath;
    Install-GitHubCli -LogFilePath $LogFilePath;
    Install-GoogleCloudCli -LogFilePath $LogFilePath;
    Install-NuGetPackageProvider -LogFilePath $LogFilePath;
    Install-PowerShell `
        -LogFilePath $LogFilePath `
        -Version 'latest';
    Install-7Zip `
        -LogFilePath $LogFilePath `
        -Version '22.01';
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
