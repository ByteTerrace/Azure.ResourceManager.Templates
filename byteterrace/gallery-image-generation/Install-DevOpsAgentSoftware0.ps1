[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AgentToolsDirectoryPath = ''
);

function Add-BillOfMaterialsEntry {
    param(
        [string]$AgentToolsDirectoryPath,
        [string]$Name,
        [string]$Publisher,
        [string]$SourceUri,
        [string]$ValidationScript,
        [string]$Version
    );

    $rs = [char]::ConvertFromUtf32(30);

    Add-Content `
        -Path ([IO.Path]::Combine($AgentToolsDirectoryPath, 'BillOfMaterials.log')) `
        -Value "${Name}${rs}${Publisher}${rs}${SourceUri}${rs}${ValidationScript}${rs}${Version}";
}
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
function Disable-InternetExplorerEnhancedSecurityConfiguration {
    $adminKey = 'HKLM:/SOFTWARE/Microsoft/Active Setup/Installed Components/{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}';
    $userKey = 'HKLM:/SOFTWARE/Microsoft/Active Setup/Installed Components/{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}';

    Set-ItemProperty `
        -Name 'IsInstalled' `
        -Path $adminKey `
        -Type 'DWORD' `
        -Value 0;
    Set-ItemProperty `
        -Name 'IsInstalled' `
        -Path $userKey `
        -Type 'DWORD' `
        -Value 0;
    Stop-Process `
        -Force `
        -Name 'Explorer';
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
function Enable-DeveloperMode {
    $path = 'HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/AppModelUnlock';

    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $path |
        Out-Null;
    New-ItemProperty `
        -Name 'AllowDevelopmentWithoutDevLicense' `
        -Path $path `
        -Type 'DWORD' `
        -Value 1 |
        Out-Null;
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
        [string]$SourceUri,
        [string]$TargetPath
    );

    $webClient = $null;

    try {
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
        [string]$AgentToolsDirectoryPath
    );

    $sourceFileName = 'AWSCLIV2.msi';
    $sourceUri = "https://awscli.amazonaws.com/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name 'Amazon Web Services CLI' `
        -Publisher 'Amazon' `
        -SourceUri $sourceUri `
        -ValidationScript '(aws --version).Split('' '')[0].Split(''/'')[1];' `
        -Version 'latest';

    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, $sourceFileName));

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
        [string]$AgentToolsDirectoryPath
    );

    $extensionsPath = ([IO.Path]::Combine(${Env:CommonProgramFiles}, 'AzureCliExtensions'));
    $sourceUri = 'https://aka.ms/installazurecliwindows';

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name 'Azure CLI' `
        -Publisher 'Microsoft' `
        -SourceUri $sourceUri `
        -ValidationScript 'az version --output ''tsv'' --query ''\"azure-cli\"'';' `
        -Version 'latest';

    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, 'azure-cli.msi'));

    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $extensionsPath |
        Out-Null;
    [Environment]::SetEnvironmentVariable(
            'AZURE_EXTENSION_DIR',
            $extensionsPath,
            [EnvironmentVariableTarget]::Machine
        );

    $extensionsPathAcl = Get-Acl -Path $extensionsPath;
    $extensionsPathAcl.SetAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
            'Users',
            ([Security.AccessControl.FileSystemRights]::FullControl),
            ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit),
            ([Security.AccessControl.PropagationFlags]::None),
            ([Security.AccessControl.AccessControlType]::Allow)
        ));
    Set-Acl `
        -AclObject $extensionsPathAcl `
        -Path $extensionsPath;

    $process = Start-Process `
        -ArgumentList @(
            '/i', "`"${installerFilePath}`"",
            '/norestart',
            '/qn'
        ) `
        -FilePath "msiexec.exe" `
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
function Install-GitHubCli {
    param(
        [string]$AgentToolsDirectoryPath
    );

    $sourceUri = 'https://api.github.com/repos/cli/cli/releases/latest';

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name 'GitHub CLI' `
        -Publisher 'GitHub' `
        -SourceUri $sourceUri `
        -ValidationScript '(gh --version).Split('' '')[2];' `
        -Version 'latest';

    $installerFilePath = Get-File `
        -SourceUri ((Invoke-RestMethod `
            -Method 'GET' `
            -Uri $sourceUri `
            -UseBasicParsing).assets.browser_download_url -match 'windows_amd64.msi' |
            Select-Object -First 1) `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, 'GitHubCli_Windows_Amd64.msi'));

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
        [string]$AgentToolsDirectoryPath
    );

    $sourceFileName = 'GoogleCloudSDKInstaller.exe';
    $sourceUri = "https://dl.google.com/dl/cloudsdk/channels/rapid/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name 'Google Cloud CLI' `
        -Publisher 'Google' `
        -SourceUri $sourceUri `
        -ValidationScript '(gcloud version).Split('' '')[3];' `
        -Version 'latest';

    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, $sourceFileName));

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
        [string]$AgentToolsDirectoryPath
    );

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
        [string]$AgentToolsDirectoryPath,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = (Invoke-WebRequest `
            -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json' `
            -UseBasicParsing |
            ConvertFrom-Json).LTSReleaseTag.Substring(1);
    }

    $sourceFileName = "PowerShell-${Version}-win-x64.msi";
    $sourceUri = "https://github.com/PowerShell/PowerShell/releases/download/v${Version}/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name 'PowerShell' `
        -Publisher 'Microsoft' `
        -SourceUri $sourceUri `
        -ValidationScript '$PSVersionTable.PSVersion;' `
        -Version $Version;

    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, $sourceFileName));

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
        [string]$AgentToolsDirectoryPath,
        [hashtable[]]$Features
    );

    foreach ($feature in $Features) {
        Write-Log `
            -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
            -Message "Installing Windows feature '$($feature.Name)'.";
        Install-WindowsFeature @feature | Out-Null;
    }
}
function Install-WindowsOptionalFeatures {
    param (
        [string]$AgentToolsDirectoryPath,
        [string[]]$FeatureNames
    );

    foreach ($name in $FeatureNames) {
        Write-Log `
            -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
            -Message "Enabling Windows optional feature '${name}'.";
        Enable-WindowsOptionalFeature `
            -FeatureName $name `
            -NoRestart `
            -Online |
            Out-Null;
    }
}
function Install-7Zip {
    param(
        [string]$AgentToolsDirectoryPath,
        [string]$Version
    );

    $sourceFileName = "7z$($Version.Replace('.', ''))-x64.exe";
    $sourceUri = "https://www.7-zip.org/a/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Name '7-Zip' `
        -Publisher 'Igor Pavlov' `
        -SourceUri $sourceUri `
        -ValidationScript '(& "${Env:ProgramFiles}/7-Zip/7z.exe" --help).Split('' '')[2];' `
        -Version $Version;

    $installerFilePath = Get-File `
        -SourceUri $sourceUri `
        -TargetPath ([IO.Path]::Combine($AgentToolsDirectoryPath, $sourceFileName));

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
        [string]$AgentToolsDirectoryPath,
        [long]$MaximumSize
    );

    $driveLetter = ${Env:SystemDrive}[0];

    if (0 -ge $MaximumSize) {
        $MaximumSize = (Get-PartitionSupportedSize -DriveLetter $driveLetter).SizeMax;
    }

    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message "Ensuring that system drive '${driveLetter}' size matches requested size of ${MaximumSize} bytes.";

    if ($MaximumSize -gt (Get-Partition -DriveLetter $driveLetter).Size) {
        Resize-Partition `
            -DriveLetter $driveLetter `
            -Size $MaximumSize;
    }
}
function Set-WindowsGraphicsDeviceInterfaceConfiguration {
    param(
        [string]$AgentToolsDirectoryPath
    );

    $processHandleQuota = 20480;

    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message "Configuring Windows Graphics Device Interface.";
    Set-ItemProperty `
        -Name 'GDIProcessHandleQuota' `
        -Path 'HKLM:/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Windows' `
        -Type 'DWORD' `
        -Value $processHandleQuota;
    Set-ItemProperty `
        -Name 'GDIProcessHandleQuota' `
        -Path 'HKLM:/SOFTWARE/WOW6432Node/Microsoft/Windows NT/CurrentVersion/Windows' `
        -Type 'DWORD' `
        -Value $processHandleQuota;
}
function Set-WindowsDefenderConfiguration {
    param(
        [string]$AgentToolsDirectoryPath
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
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message "Configuring Windows Defender.";

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
        [string]$AgentToolsDirectoryPath
    );

    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message "Configuring Windows Error Reporting.";
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
        [string]$AgentToolsDirectoryPath,
        [string]$Message
    );

    Add-Content `
        -Path ([IO.Path]::Combine(${AgentToolsDirectoryPath}, 'InstallDevOpsAgentSoftwareMessages.log')) `
        -Value "[Install-DevOpsAgentSoftware0.ps1@$(Get-TimeMarker)] - ${Message}";
}

Set-StrictMode -Version 'Latest';

try {
    if ([string]::IsNullOrEmpty($AgentToolsDirectoryPath)) {
        $AgentToolsDirectoryPath = "${Env:SystemDrive}/DevOpsAgentTools";
    }

    $AgentToolsDirectoryPath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $AgentToolsDirectoryPath).FullName;
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;';
    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;';
    [Environment]::SetEnvironmentVariable(
            'AGENT_TOOLSDIRECTORY',
            $AgentToolsDirectoryPath,
            [EnvironmentVariableTarget]::Machine
        );
    Disable-Debuggers;
    Disable-InternetExplorerEnhancedSecurityConfiguration;
    Disable-NetworkDiscoverabilityPopup;
    Disable-ServerManagerPopup;
    Disable-UserAccessControl;
    Enable-DeveloperMode;
    Enable-LongPathBehavior;
    Enable-RootHypervisorScheduler;
    Set-WindowsDefenderConfiguration -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Set-WindowsErrorReportingConfiguration -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Set-WindowsGraphicsDeviceInterfaceConfiguration -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Resize-SystemDrive `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -MaximumSize 0;
    Install-WindowsFeatures `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
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
        );
    Install-WindowsOptionalFeatures `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -FeatureNames @(
            'Client-ProjFS',
            'HypervisorPlatform',
            'Microsoft-Windows-Subsystem-Linux',
            'VirtualMachinePlatform'
        );
    Enable-DotNetStrongCrypto;
    Install-AmazonWebServicesCli -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Install-AzureCli -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Install-GitHubCli -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Install-GoogleCloudCli -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Install-NuGetPackageProvider -AgentToolsDirectoryPath $AgentToolsDirectoryPath;
    Install-PowerShell `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Version 'latest';
    Install-7Zip `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Version '22.01';
    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message 'Complete!';
}
catch {
    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message $_;
    Write-Log `
        -AgentToolsDirectoryPath $AgentToolsDirectoryPath `
        -Message 'Failed!';

    throw;
}
