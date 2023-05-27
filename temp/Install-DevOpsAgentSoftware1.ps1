param(
    [string]$LogFilePath
);

function Get-File {
    param(
        [string]$SourceUri,
        [string]$TargetPath
    );

    $webClient = $null;

    try {
        $webClient = [Net.WebClient]::new();
        $webClient.DownloadFile($SourceUri, $TargetPath);

        return $TargetPath;
    }
    finally {
        $webClient.Dispose();
    }

    return $null;
}
function Get-TimeMarker {
    return Get-Date -Format "yyyyMMddTHH:mm:ssK";
}
function Install-VisualStudioExtension {
    param(
        [string]$Name,
        [string]$Publisher,
        [string]$Version
    );

    $fileName = "${Name}.vsix";
    $filePath = Get-File `
        -SourceUri "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${Publisher}/vsextensions/${Name}/${Version}/vspackage" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $fileName));
    $visualStudioBasePath = $ null;

    try {
        $visualStudioBasePath = (& "${Env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe" -latest -property installationPath);
    }
    catch [Management.Automation.CommandNotFoundException] {
        throw 'Unable to find ''vswhere.exe''; Visual Studio must be installed before running this script.';
    }

    $process = Start-Process `
        -ArgumentList @(
            '/quiet',
            "`"${filePath}`""
        ) `
        -FilePath "${visualStudioBasePath}/Common7/IDE/VSIXInstaller.exe" `
        -PassThru `
        -Wait;

    if ((0 -ne $process.ExitCode) -and (1001 -ne $process.ExitCode)) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }
}
function Install-VsixBootstrapper {
    param(
        [string]$Version
    );

    $fileName = 'VSIXBootstrapper.exe';
    $filePath = Get-File `
        -SourceUri "https://github.com/microsoft/vsixbootstrapper/releases/download/${Version}/${fileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $fileName));

    Write-Host $filePath;
}
function Install-VsWhere {
    param(
        [string]$Version
    );

    $fileName = 'vswhere.exe';
    $filePath = Get-File `
        -SourceUri "https://github.com/microsoft/vswhere/releases/download/${Version}/${fileName}" `
        -TargetPath ([IO.Path]::Combine((Get-Location), $fileName));

    Write-Host $filePath;
}
function Write-Log {
    param(
        [string]$Message,
        [string]$Path
    );

    Add-Content `
        -Path $Path `
        -Value "[$([IO.Path]::GetFileName($PSCommandPath))@$(Get-TimeMarker)] - ${Message}";
}

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

$isLoggingEnabled = (-not [string]::IsNullOrEmpty($LogFilePath));

if ($isLoggingEnabled) {
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::GetDirectoryName($LogFilePath));
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
        -Name $extension.Name `
        -Publisher $extension.Publisher `
        -Version $extension.Version;
};

if ($isLoggingEnabled) {
    Write-Log `
        -Message 'Complete!' `
        -Path $LogFilePath;
}
