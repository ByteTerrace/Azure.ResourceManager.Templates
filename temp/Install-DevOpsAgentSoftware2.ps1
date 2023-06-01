param(
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
function Install-AzureCliExtension {
    param(
        [string]$LogFilePath,
        [string]$Name
    );

    Write-Log `
        -Message "Installing Azure CLI extension: ${Name}." `
        -Path $LogFilePath;

    az extension add `
        --name $Name `
        --yes;
}
function Install-GoogleChrome {
    param(
        [string]$LogFilePath
    );

    $installerFileName = 'googlechromestandaloneenterprise64.msi';
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://dl.google.com/tag/s/dl/chrome/install/${installerFileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message 'Installing Google Chrome.' `
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

    New-NetFirewallRule `
        -Action Block `
        -DisplayName 'BlockGoogleUpdate' `
        -Direction Outbound `
        -Program ((Get-Item -Path "${Env:ProgramFiles(x86)}/Google/Update/GoogleUpdate.exe").FullName) |
        Out-Null;

    @(
        'gupdate',
        'gupdatem'
    ) | ForEach-Object {
        $service = Get-Service -Name $_;
        $service | Set-Service -StartupType ([ServiceProcess.ServiceStartMode]::Disabled);
        $service | Stop-Service;
        $service.WaitForStatus('Stopped', '00:00:53');
    }

    $googleChromeRegistryPath = 'HKLM:/SOFTWARE/Policies/Google/Chrome';
    $googleUpdateRegistryPath = 'HKLM:/SOFTWARE/Policies/Google/Update';

    New-Item -Force -Path $googleChromeRegistryPath | Out-Null;
    New-Item -Force -Path $googleUpdateRegistryPath | Out-Null;

    @(
        @{
            Name = 'AutoUpdateCheckPeriodMinutes';
            Value = 0;
        }
        @{
            Name = 'DisableAutoUpdateChecksCheckboxValue';
            Value = 1;
        }
        @{
            Name = 'UpdateDefault';
            Value = 0;
        }
        @{
            Name = 'Update{8A69D345-D564-463C-AFF1-A69D9E530F96}';
            Value = 0;
        }
    ) | ForEach-Object {
        New-ItemProperty `
            -Force `
            -Path $googleUpdateRegistryPath `
            -Name ($_.Name) `
            -Type 'DWORD' `
            -Value ($_.Value) |
            Out-Null;
    }

    New-ItemProperty `
        -Force `
        -Path $googleChromeRegistryPath `
        -Name 'DefaultBrowserSettingEnabled' `
        -Type 'DWORD' `
        -Value 0 |
        Out-Null;
}
function Install-MozillaFirefox {
    param(
        [string]$LogFilePath,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = (Invoke-WebRequest `
            -Uri 'https://product-details.mozilla.org/1.0/firefox_versions.json' `
            -UseBasicParsing |
            ConvertFrom-Json).LATEST_FIREFOX_VERSION;
    }

    $installerFileName = "Firefox_Windows_Amd64.exe";
    $installerFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://download.mozilla.org/?lang=en-US&product=firefox-${Version}&os=win64" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $installerFileName));

    Write-Log `
        -Message "Installing Mozilla Firefox ${Version}." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @(
            '/install',
            '/silent'
        ) `
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

    $basePath = "${Env:ProgramFiles}/Mozilla Firefox";

    New-Item `
        -Force `
        -ItemType 'File' `
        -Name 'mozilla.cfg' `
        -Path $basePath `
        -Value @'
//
pref("app.update.enabled", false);
pref("browser.shell.checkDefaultBrowser", false);
'@ |
        Out-Null;
    New-Item `
        -Force `
        -ItemType 'File' `
        -Name 'local-settings.js' `
        -Path ([IO.Path]::Combine($basePath, 'defaults/pref')) `
        -Value @'
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
'@ |
        Out-Null;
}
function Install-VisualStudioExtension {
    param(
        [string]$LogFilePath,
        [string]$Name,
        [string]$Publisher,
        [string]$Version
    );

    $extensionFilePath = Get-File `
        -LogFilePath $LogFilePath `
        -SourceUri "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${Publisher}/vsextensions/${Name}/${Version}/vspackage" `
        -TargetPath ([IO.Path]::Combine((Get-Location), "${Name}.vsix"));

    Write-Log `
        -Message "Installing Visual Studio extension '${Publisher}-${Name} ${Version}'." `
        -Path $LogFilePath;

    $process = Start-Process `
        -ArgumentList @(
            '/quiet',
            "`"${extensionFilePath}`""
        ) `
        -FilePath "${Env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/resources/app/ServiceHub/Services/Microsoft.VisualStudio.Setup.Service/VSIXInstaller.exe" `
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
        -Value "[Install-DevOpsAgentSoftware2.ps1@$(Get-TimeMarker)] - ${Message}";
}

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

    @(
        'azure-batch-cli-extensions',
        'azure-cli-ml',
        'azure-devops',
        'front-door',
        'k8s-configuration',
        'k8s-extension',
        'resource-graph'
    ) | ForEach-Object {
        $extension = $_;

        Install-AzureCliExtension `
            -LogFilePath $LogFilePath `
            -Name $extension;
    }
    @(
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
    ) | ForEach-Object {
        $extension = $_;

        Install-VisualStudioExtension `
            -LogFilePath $LogFilePath `
            -Name $extension.Name `
            -Publisher $extension.Publisher `
            -Version $extension.Version;
    }
    Install-GoogleChrome -LogFilePath $LogFilePath;
    Install-MozillaFirefox `
        -LogFilePath $LogFilePath `
        -Version 'latest';
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
