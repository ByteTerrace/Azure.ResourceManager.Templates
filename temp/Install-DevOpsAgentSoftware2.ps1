param(
    [string]$LogFilePath
);

$command = {
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

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'C:/WindowsAzure/ByteTerrace/main.log';
    }

    $visualStudioExtensions = @(
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
            -LogFilePath $LogFilePath `
            -Name $extension.Name `
            -Publisher $extension.Publisher `
            -Version $extension.Version;
    };

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
};

$tempScriptPath = [IO.Path]::Combine([IO.Path]::GetTempPath(), "$([guid]::NewGuid()).ps1");

$command | Out-File -FilePath $tempScriptPath;

& pwsh.exe -File $tempScriptPath $LogFilePath;

Start-Sleep -Seconds 3;

if (Test-Path -Path $tempScriptPath) {
    Remove-Item `
        -Force `
        -Path $tempScriptPath;
}
