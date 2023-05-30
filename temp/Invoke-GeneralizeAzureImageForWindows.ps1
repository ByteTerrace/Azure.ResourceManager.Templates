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
        [string]$Message,
        [string]$Path
    );

    Add-Content `
        -Path $Path `
        -Value "[Invoke-GeneralizeAzureImageForWindows.ps1@$(Get-TimeMarker)] - ${Message}";
}

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;

    if ([string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = 'C:/WindowsAzure/ByteTerrace/main.log';
    }

    Confirm-Environment;

    $attemptDelayTimeInSeconds = 13;
    $commandTimeoutInMinutes = 17;
    $currentNumberOfAttempts = 0;
    $maximumNumberOfAttempts = (($commandTimeoutInMinutes * 60) / $attemptDelayTimeInSeconds);
    $setupStateKeyPath = 'HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Setup/State';
    $unattendXmlPath = "${Env:SystemRoot}/system32/Sysprep/unattend.xml";
    $waitForServiceNames = @(
        'RdAgent',
        'WindowsAzureGuestAgent',
        'WindowsAzureTelemetryService'
    );

    $waitForServiceNames | ForEach-Object {
        $serviceName = $_;

        if (Get-Service -ErrorAction ([Management.Automation.ActionPreference]::SilentlyContinue) -Name $serviceName) {
            Write-Log `
                -Message "Waiting for $serviceName..." `
                -Path $LogFilePath;

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
        Write-Log `
            -Message $imageState `
            -Path $LogFilePath;

        Start-Sleep -Seconds $attemptDelayTimeInSeconds;
    }

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
