param(
    [string]$LogFilePath
);

function Confirm-Environment {
    try {
        Invoke-RestMethod `
            -Headers @{ 'Metadata' = 'true' } `
            -Method 'GET' `
            -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01';
    }
    catch [Net.Sockets.SocketException], [Net.WebException] {
        throw 'Unable to access Azure IMDS.';
    }
}
function Get-TimeMarker {
    return Get-Date -Format "yyyyMMddTHH:mm:ssK";
}
function Write-Log {
    param(
        [string]$LogFilePath,
        [string]$Message
    );

    Add-Content `
        -Path $LogFilePath `
        -Value "[Invoke-GeneralizeAzureImageForWindows.ps1@$(Get-TimeMarker)] - ${Message}";
}

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

Confirm-Environment;

$attemptDelayTimeInSeconds = 13;
$commandTimeoutInMinutes = 17;
$currentNumberOfAttempts = 0;
$isLoggingEnabled = (-not [string]::IsNullOrEmpty($LogFilePath));
$maximumNumberOfAttempts = (($commandTimeoutInMinutes * 60) / $attemptDelayTimeInSeconds);
$setupStateKeyPath = 'HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Setup/State';
$unattendXmlPath = "${Env:SystemRoot}/system32/Sysprep/unattend.xml";
$waitForServiceNames = @(
    'RdAgent',
    'WindowsAzureGuestAgent',
    'WindowsAzureTelemetryService'
);

if ($isLoggingEnabled) {
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::GetDirectoryName($LogFilePath));
}

$waitForServiceNames | ForEach-Object {
    $serviceName = $_;

    if (Get-Service -ErrorAction ([Management.Automation.ActionPreference]::SilentlyContinue) -Name $serviceName) {
        if ($isLoggingEnabled) {
            Write-Log `
                -Message "Waiting for $serviceName..." `
                -Path $LogFilePath;
        }

        while (($maximumNumberOfAttempts -gt ++$currentNumberOfAttempts) -and ('Running' -ne (Get-Service -Name $serviceName).Status)) {
            Start-Sleep -Seconds $attemptDelayTimeInSeconds;
        }
    }
};

if (Test-Path -Path $unattendXmlPath) {
    Remove-Item -Force -Path $unattendXmlPath;
}

& "${Env:SystemRoot}/System32/Sysprep/sysprep.exe" /oobe /generalize /quiet /quit;

while (($maximumNumberOfAttempts -gt ++$currentNumberOfAttempts) -and ('IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE' -ne ($imageState = (Get-ItemProperty -Path $setupStateKeyPath).ImageState))) {
    if ($isLoggingEnabled) {
        Write-Log `
            -Message $imageState `
            -Path ([IO.Path]::GetDirectoryName($LogFilePath));
    }

    Start-Sleep -Seconds $attemptDelayTimeInSeconds;
}

if ($isLoggingEnabled) {
    Write-Log `
        -Message 'Complete!' `
        -Path $LogFilePath;
}