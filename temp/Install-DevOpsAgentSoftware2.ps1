[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
);

class DotNetSdkVersionsManifest {
    [Text.Json.Serialization.JsonPropertyName('latest-release')]
    [string]$LatestReleaseVersion;
    [Text.Json.Serialization.JsonPropertyName('latest-sdk')]
    [string]$LatestSdkVersion;
    [string]$Product;
    [Text.Json.Serialization.JsonPropertyName('release-type')]
    [string]$ReleaseType;
    [Text.Json.Serialization.JsonPropertyName('releases.json')]
    [string]$ReleasesUri;
    [Text.Json.Serialization.JsonPropertyName('support-phase')]
    [string]$SupportPhase;
}
class GitHubActionsReleaseFile {
    [Text.Json.Serialization.JsonPropertyName('arch')]
    [string]$Architecture;
    [Text.Json.Serialization.JsonPropertyName('download_url')]
    [string]$DownloadUri;
    [Text.Json.Serialization.JsonPropertyName('filename')]
    [string]$FileName;
    [string]$Platform;
    [Text.Json.Serialization.JsonPropertyName('platform_version')]
    [string]$PlatformVersion;
}
class GitHubActionsVersionsManifest {
    [GitHubActionsReleaseFile[]]$Files;
    [Text.Json.Serialization.JsonPropertyName('stable')]
    [bool]$IsStable
    [Text.Json.Serialization.JsonPropertyName('release_url')]
    [string]$ReleaseUri;
    [string]$Version;
}
class HttpService {
    [Net.Http.HttpClient]$HttpClient;

    HttpService([Net.Http.HttpClient]$httpClient) {
        $this.HttpClient = $httpClient;
    }

    hidden [Net.Http.HttpResponseMessage] SendRequest(
        [Net.Http.HttpContent]$content,
        [Net.Http.HttpMethod]$method,
        [string]$uri
    ) {
        [Net.Http.HttpRequestMessage]$requestMessage = $null;

        try {
            $requestMessage = [Net.Http.HttpRequestMessage]::new();
            $requestMessage.Method = $method;
            $requestMessage.RequestUri = $uri;

            if ($null -ne $content) {
                $requestMessage.Content = $content;
            }

            return $this.HttpClient.Send(
                $requestMessage,
                [Net.Http.HttpCompletionOption]::ResponseContentRead,
                [Threading.CancellationToken]::None
            );
        }
        finally {
            if ($null -ne $requestMessage) {
                $requestMessage.Dispose();
            }
        }
    }

    [string] DownloadFile(
        [string]$filePath,
        [string]$uri
    ) {
        $this.Get(
            [Action[Net.Http.HttpResponseMessage]] {
                param([Net.Http.HttpResponseMessage]$responseMessage);

                [IO.FileStream]$fileStream = $null;

                try {
                    $fileStream = [IO.FileStream]::new(
                        $filePath,
                        [IO.FileMode]::CreateNew,
                        [IO.FileAccess]::Write,
                        [IO.FileShare]::None,
                        0,
                        [IO.FileOptions]::None
                    );

                    $responseMessage.Content.CopyTo(
                        $fileStream,
                        $null,
                        [Threading.CancellationToken]::None
                    );
                }
                finally {
                    if ($null -ne $fileStream) {
                        $fileStream.Dispose();
                    }
                }
            },
            $uri
        );

        return $filePath;
    }
    [void] Get(
        [Action[Net.Http.HttpResponseMessage]]$handler,
        [string]$uri
    ) {
        [Net.Http.HttpResponseMessage]$responseMessage = $null;

        try {
            $responseMessage = $this.SendRequest(
                $null,
                [Net.Http.HttpMethod]::Get,
                $uri
            );

            $responseMessage.EnsureSuccessStatusCode();
            $handler.Invoke($responseMessage);
        }
        finally {
            if ($null -ne $responseMessage) {
                $responseMessage.Dispose();
            }
        }
    }
    [object] GetJsonAsT(
        [Text.Json.JsonSerializerOptions]$jsonSerializerOptions,
        [Type]$type,
        [string]$uri
    ) {
        if ($null -eq $jsonSerializerOptions) {
            $jsonSerializerOptions = [Text.Json.JsonSerializerOptions]::new();
            $jsonSerializerOptions.PropertyNamingPolicy = [Text.Json.JsonNamingPolicy]::CamelCase;
        }

        $result = $null;

        $this.Get(
            [Action[Net.Http.HttpResponseMessage]] {
                param([Net.Http.HttpResponseMessage]$responseMessage);

                ([ref]$result).Value = [Text.Json.JsonSerializer]::Deserialize(
                    $responseMessage.Content.ReadAsStream(),
                    $type,
                    $jsonSerializerOptions
                );
            },
            $uri
        );

        return $result;
    }
}
class MozillaFirefoxVersionsManifest {
    [Text.Json.Serialization.JsonPropertyName('LATEST_FIREFOX_VERSION')]
    [string]$LatestVersion;
}
class NodeJsVersionsManifest {
    [string[]]$Files;
    [Text.Json.Serialization.JsonPropertyName('lts')]
    [object]$LongTermSupport;
    [string]$Version;
}

function Add-MachinePath {
    param (
        [string]$Path
    );

    Set-MachineVariable `
        -Name 'Path' `
        -Value "$(Get-MachineVariable -Name 'Path');$((Get-Item -Path $Path).FullName)";
}
function Get-DotNetSdkVersionsManifest {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$ReleaseType,
        [string]$Version
    );

    [Text.Json.JsonSerializer]::Deserialize(
            ($HttpService.GetJsonAsT(
                    $JsonSerializerOptions,
                    [Collections.Generic.Dictionary[string,Text.Json.JsonElement]],
                    'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json'
                ))['releases-index'],
            [DotNetSdkVersionsManifest[]],
            $JsonSerializerOptions
        ) |
        Where-Object {
            ('preview' -ne $_.SupportPhase) -and
            ([string]::IsNullOrEmpty($ReleaseType) -or ($_.ReleaseType -eq $ReleaseType)) -and
            ([string]::IsNullOrEmpty($Version) -or ($_.LatestSdkVersion -like $Version));
        } |
        Sort-Object -Descending { ([version]$_.LatestSdkVersion); } |
        Select-Object -First 1;
}
function Get-GitHubActionsToolPath {
    param(
        [string]$Architecture,
        [string]$ToolName,
        [string]$Version
    );

    return [IO.Path]::Combine(
            (Get-Item -Path ([IO.Path]::Combine([IO.Path]::Combine((Get-MachineVariable -Name 'AGENT_TOOLSDIRECTORY'), $ToolName), $Version)) |
                Sort-Object -Descending { ([version]$_.name); } |
                Select-Object -First 1).FullName,
            $Architecture
        );
}
function Get-GitHubActionsVersionsManifest {
    param(
        [string]$Architecture,
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$ToolName,
        [string]$Version
    );

    return $HttpService.GetJsonAsT(
            $JsonSerializerOptions,
            [GitHubActionsVersionsManifest[]],
            "https://raw.githubusercontent.com/actions/${ToolName}-versions/main/versions-manifest.json"
        ) |
        Where-Object { (
            $_.IsStable -and
            ($_.Version -like $Version)
        ); } |
        Select-Object -ExpandProperty 'Files' |
        Where-Object { (
            ($Architecture -eq $_.Architecture) -and
            ($Platform -eq $_.Platform)
        ); } |
        Sort-Object { ([version]$_.Version); } |
        Select-Object -First 1;
}
function Get-MachineVariable {
    param(
        [string]$Name
    );

    return [Environment]::GetEnvironmentVariable($Name, [EnvironmentVariableTarget]::Machine);
}
function Install-AzureCliExtensions {
    @(
        'azure-cli-ml',
        'azure-devops',
        'front-door',
        'k8s-configuration',
        'k8s-extension',
        'resource-graph'
    ) |
        ForEach-Object {
            az extension add `
                --name $_ `
                --yes;
        }
}
function Install-AzureCopy {
    param(
        [HttpService]$HttpService
    );

    $azCopyPath = [IO.Path]::Combine((Get-MachineVariable -Name 'AGENT_TOOLSDIRECTORY'), 'azcopy');
    $installerFileName = "azcopy_windows_amd64.zip";
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerFileName)),
            'https://aka.ms/downloadazcopy-v10-windows'
        );

    & "${Env:ProgramFiles}/7-Zip/7z.exe" `
        x $installerFilePath `
        "-o${azCopyPath}" `
        -y |
        Out-Null;

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }

    Add-MachinePath -Path ((Get-ChildItem -Path "${azCopyPath}/*" | Select-Object -First 1).FullName);
}
function Install-DotNetSdk {
    param(
        [string]$Architecture,
        [HttpService]$HttpService,
        [string]$InstallerFilePath,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$ReleaseType,
        [string]$SdkDirectoryPath,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Architecture)) {
        $Architecture = 'x64';
    }

    if ([string]::IsNullOrEmpty($Version) -or $Version.Contains('*')) {
        $Version = (Get-DotNetSdkVersionsManifest `
            -HttpService $httpService `
            -JsonSerializerOptions $JsonSerializerOptions `
            -ReleaseType $ReleaseType `
            -Version $Version).LatestSdkVersion;
    }

    & $InstallerFilePath `
        -Architecture $Architecture `
        -InstallDir $SdkDirectoryPath `
        -Version $Version |
        Out-Null;
}
function Install-DotNetSdks {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    Set-MachineVariable `
        -Name 'DOTNET_MULTILEVEL_LOOKUP' `
        -Value '0';
    Set-MachineVariable `
        -Name 'DOTNET_NOLOGO' `
        -Value '1';
    Set-MachineVariable `
        -Name 'DOTNET_SKIP_FIRST_TIME_EXPERIENCE' `
        -Value '1';

    $installerFileName = 'dotnet-install.ps1';
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerFileName)),
            "https://dot.net/v1/${installerFileName}"
        );
    $sdkDirectoryPath = ([IO.Path]::Combine(${Env:ProgramFiles}, 'dotnet'));

    @(
        '3.1.*',
        '6.0.*'
    ) |
        ForEach-Object {
            Install-DotNetSdk `
                -HttpService $HttpService `
                -InstallerFilePath $installerFilePath `
                -JsonSerializerOptions $JsonSerializerOptions `
                -SdkDirectoryPath $sdkDirectoryPath `
                -Version $_;
        }
}
function Install-GitHubActionsTool {
    param(
        [string]$Architecture,
        [HttpService]$HttpService,
        [string]$Platform,
        [string]$ToolName,
        [string]$Version
    );

    $installerData = Get-GitHubActionsVersionsManifest `
        -Architecture $Architecture `
        -HttpService $HttpService `
        -LogFilePath $LogFilePath `
        -Platform $Platform `
        -ToolName $ToolName `
        -Version $Version;
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerData.FileName)),
            $installerData.DownloadUri
        );
    $installerFolderPath = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetFileNameWithoutExtension($installerData.FileName));

    & "${Env:ProgramFiles}/7-Zip/7z.exe" `
        x $installerFilePath `
        "-o${installerFolderPath}" `
        -y |
        Out-Null;

    Push-Location -Path $installerFolderPath;

    try {
        Invoke-Expression ./setup.ps1 | Out-Null;
    }
    finally {
        Pop-Location;
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }
}
function Install-GitHubActionsTools {
    $gitHubActionsTools = @(
        @{
            Architectures = @( 'x64' );
            Name = 'Go';
            Versions = @(
                '1.18.*',
                '1.19.*',
                '1.20.*'
            );
        },
        @{
            Architectures = @( 'x64' );
            Name = 'Node';
            Versions = @(
                '14.*',
                '16.*',
                '18.*'
            );
        },
        @{
            Architectures = @(
                'x64',
                'x86'
            );
            DefaultArchitecture = 'x86';
            Name = 'Python';
            Versions = @(
                '3.7.*',
                '3.8.*',
                '3.9.*',
                '3.10.*'
                '3.11.*'
            );
        }
    );

    $gitHubActionsTools |
        ForEach-Object {
            $tool = $_;

            foreach ($architecture in $tool.Architectures) {
                foreach ($version in $tool.Versions) {
                    Install-GitHubActionsTool `
                        -Architecture $architecture `
                        -HttpService $httpService `
                        -Platform 'win32' `
                        -ToolName $tool.Name `
                        -Version $version;
                }
            }
        }
    $gitHubActionsTools |
        ForEach-Object {
            $architecture = $_.DefaultArchitecture;
            $toolName = $_.Name;
            $version = $_.DefaultVersion;

            if ($null -eq $architecture) {
                $architecture = 'x64';
            }

            $toolPath = Get-GitHubActionsToolPath `
                -Architecture $architecture `
                -ToolName $toolName `
                -Version ($_.Versions |
                    Where-Object { ([string]::IsNullOrEmpty($version) -or ($_ -like $version)); } |
                    Sort-Object -Descending { ([version]$_.Replace('*', '0')); } |
                    Select-Object -First 1);

            if ('Go' -eq $toolName) {
                Add-MachinePath -Path "${toolPath}/bin";
            }

            if ('Python' -eq $toolName) {
                Add-MachinePath -Path $toolPath;
                Add-MachinePath -Path "${toolPath}/Scripts";
            }
        }
    Update-EnvironmentVariables;
}
function Install-GoogleChrome {
    param(
        [HttpService]$HttpService
    );

    $installerFileName = 'googlechromestandaloneenterprise64.msi';
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerFileName)),
            "https://dl.google.com/tag/s/dl/chrome/install/${installerFileName}"
        );

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
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = $HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [MozillaFirefoxVersionsManifest],
                'https://product-details.mozilla.org/1.0/firefox_versions.json'
            ).LatestVersion;
    }

    $installerFileName = "Firefox_Windows_x64.exe";
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerFileName)),
            "https://download.mozilla.org/?lang=en-US&product=firefox-${Version}&os=win64"
        );

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
function Install-NodeJs {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = ($HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [NodeJsVersionsManifest[]],
                'https://nodejs.org/download/release/index.json'
            ) |
            Where-Object { (($_.LongTermSupport -as [string]) -ne 'false'); } |
            Sort-Object -Descending { ([version]$_.Version.Substring(1)); } |
            Select-Object -First 1).Version.Substring(1);
    }

    $cachePath = 'C:/npm/cache';
    $prefixPath = 'C:/npm/prefix';

    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $cachePath |
        Out-Null;
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $prefixPath |
        Out-Null;

    $installerFileName = 'NodeJs_Windows_x64.msi';
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $installerFileName)),
            "https://nodejs.org/dist/v${Version}/node-v${Version}-x64.msi"
        );

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

    Add-MachinePath -Path $prefixPath;
    Set-MachineVariable `
        -Name 'NPM_CONFIG_PREFIX' `
        -Value $prefixPath;
    Update-EnvironmentVariables;

    npm config set cache $cachePath --global;
    npm config set registry https://registry.npmjs.org/;
}
function Install-Pipx {
    $pipxBin = "${Env:ProgramFiles(x86)}/pipx_bin";
    $pipxHome = "${Env:ProgramFiles(x86)}/pipx";

    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $pipxBin |
        Out-Null;
    New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path $pipxHome |
        Out-Null;
    Set-MachineVariable `
        -Name 'PIPX_BIN_DIR' `
        -Value $pipxBin;
    Set-MachineVariable `
        -Name 'PIPX_HOME' `
        -Value $pipxHome;

    pip install pipx;

    Add-MachinePath -Path $pipxBin;
    Update-EnvironmentVariables;
}
function Install-PowerShellModules {
    @(
        'Az',
        'DockerMsftProvider',
        'MarkdownPS',
        'Microsoft.Graph',
        'Pester',
        'PowerShellGet',
        'PSScriptAnalyzer',
        'SqlServer'
    ) |
        ForEach-Object {
            Install-Module `
                -AllowClobber `
                -Force `
                -Name $_ `
                -Repository 'PSGallery' `
                -Scope 'AllUsers';
        }
}
function Install-VisualStudioExtension {
    param(
        [HttpService]$HttpService,
        [string]$Name,
        [string]$Publisher,
        [string]$Version
    );

    $extensionFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), "${Name}.vsix")),
            "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${Publisher}/vsextensions/${Name}/${Version}/vspackage"
        );
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
function Install-VisualStudioExtensions {
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
    ) |
        ForEach-Object {
            Install-VisualStudioExtension `
                -HttpService $httpService `
                -Name $_.Name `
                -Publisher $_.Publisher `
                -Version $_.Version;
        }
}
function Set-MachineVariable {
    param(
        [string]$Name,
        [string]$Value
    );

    [Environment]::SetEnvironmentVariable(
            $Name,
            $Value,
            [EnvironmentVariableTarget]::Machine
        );
}
function Update-EnvironmentVariables {
    $originalArchitecture = ${Env:PROCESSOR_ARCHITECTURE};
    $originalPsModulePath = ${Env:PSModulePath};
    $originalUserName = ${Env:USERNAME};
    $pathEntries = ([string[]]@());

    # 0) process
    Get-ChildItem `
        -Path 'Env:\' |
        Select-Object `
            -ExpandProperty 'Key' |
            ForEach-Object {
                Set-Item `
                    -Path ('Env:{0}' -f $_) `
                    -Value ([Environment]::GetEnvironmentVariable($_, [EnvironmentVariableTarget]::Process));
            };

    # 1) machine
    $machineEnvironmentRegistryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment\');

    if ($null -ne $machineEnvironmentRegistryKey) {
        try {
            Get-Item `
                -Path 'HKLM:/SYSTEM/CurrentControlSet/Control/Session Manager/Environment' |
                Select-Object `
                    -ExpandProperty 'Property' |
                    ForEach-Object {
                        $value =  $machineEnvironmentRegistryKey.GetValue(
                                $_,
                                [string]::Empty,
                                [Microsoft.Win32.RegistryValueOptions]::None
                            );

                        Set-Item `
                            -Path ('Env:{0}' -f $_) `
                            -Value $value;

                        if ('Path' -eq $_) {
                            $pathEntries += $value.Split(';');
                        }
                    };
        }
        finally {
            $machineEnvironmentRegistryKey.Close();
        }
    }

    # 2) user
    if ($originalUserName -notin @('SYSTEM', ('{0}$' -f ${Env:COMPUTERNAME}))) {
        $userEnvironmentRegistryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment');

        if ($null -ne $userEnvironmentRegistryKey) {
            try {
                Get-Item `
                    -Path 'HKCU:/Environment' |
                    Select-Object `
                        -ExpandProperty 'Property' |
                        ForEach-Object {
                            $value =  $userEnvironmentRegistryKey.GetValue(
                                    $_,
                                    [string]::Empty,
                                    [Microsoft.Win32.RegistryValueOptions]::None
                                );

                            Set-Item `
                                -Path ('Env:{0}' -f $_) `
                                -Value $value;

                            if ('Path' -eq $_) {
                                $pathEntries += $value.Split(';');
                            }
                        };
            }
            catch {
                $userEnvironmentRegistryKey.Close();
            }
        }
    }

    ${Env:Path} = (($pathEntries | Select-Object -Unique) -Join ';');
    ${Env:PROCESSOR_ARCHITECTURE} = $originalArchitecture;
    ${Env:PSModulePath} = $originalPsModulePath;

    if ($originalUserName) {
        ${Env:USERNAME} = $originalUserName;
    }
}

[Net.Http.HttpClient]$httpClient = $null;

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;
    [Net.ServicePointManager]::SecurityProtocol = (
        [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls13
    );

    $httpClient = [Net.Http.HttpClient]::new();
    $httpClient.BaseAddress = $null;
    $httpService = [HttpService]::new($httpClient);
    $jsonSerializerOptions = [Text.Json.JsonSerializerOptions]::new();
    $jsonSerializerOptions.PropertyNamingPolicy = [Text.Json.JsonNamingPolicy]::CamelCase;

    Install-AzureCliExtensions;
    Install-AzureCopy -HttpService $httpService;
    Install-DotNetSdks `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Install-GitHubActionsTools;
    Install-GoogleChrome -HttpService $httpService;
    Install-MozillaFirefox `
        -HttpService $httpService `
        -Version 'latest';
    Install-PowerShellModules;
    Install-NodeJs `
        -HttpService $httpService `
        -Version 'latest';
    Install-Pipx;
    Install-VisualStudioExtensions;
}
catch {
    if ($null -ne $httpClient) {
        $httpClient.Dispose();
    }

    throw;
}
