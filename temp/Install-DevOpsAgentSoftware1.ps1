param(
    [string]$LogFilePath
);

function Get-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceUri,
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Publisher,
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
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
        [string]$LogFilePath,
        [string]$Message
    );

    Add-Content `
        -Path $LogFilePath `
        -Value "[$([IO.Path]::GetFileName($PSCommandPath))@$(Get-TimeMarker)] - ${Message}";
}

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

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

Write-Log `
    -Message 'Complete!' `
    -Path $LogFilePath;
