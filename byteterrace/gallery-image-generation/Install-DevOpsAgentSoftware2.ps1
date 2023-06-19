[CmdletBinding()]
param();

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
}
class GitHubActionsVersionsManifest {
    [GitHubActionsReleaseFile[]]$Files;
    [Text.Json.Serialization.JsonPropertyName('stable')]
    [bool]$IsStable
    [Text.Json.Serialization.JsonPropertyName('release_url')]
    [string]$ReleaseUri;
    [string]$Version;
}
class GitHubReleasesAsset {
    [string]$Name;
    [Text.Json.Serialization.JsonPropertyName('browser_download_url')]
    [string]$BrowserDownloadUrl;
}
class GitHubReleasesManifest {
    [GitHubReleasesAsset[]]$Assets;
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
class MobyReleasesManifest {
    [string]$Name;
    [Text.Json.Serialization.JsonPropertyName('tag_name')]
    [string]$TagName;
}
class MozillaFirefoxVersionsManifest {
    [Text.Json.Serialization.JsonPropertyName('LATEST_FIREFOX_VERSION')]
    [string]$LatestVersion;
}
class OpenSslReleaseFile {
    [Text.Json.Serialization.JsonPropertyName('arch')]
    [string]$Architecture;
    [int]$Bits;
    [Text.Json.Serialization.JsonPropertyName('installer')]
    [string]$InstallerType;
    [Text.Json.Serialization.JsonPropertyName('light')]
    [bool]$IsLight;
    [Text.Json.Serialization.JsonPropertyName('url')]
    [string]$Uri;
    [Text.Json.Serialization.JsonPropertyName('basever')]
    [string]$Version;
}
class OpenSslReleaseManifest {
    [Collections.Generic.Dictionary[string,[OpenSslReleaseFile]]]$Files;
}
class NodeJsVersionsManifest {
    [string[]]$Files;
    [Text.Json.Serialization.JsonPropertyName('lts')]
    [object]$LongTermSupport;
    [string]$Version;
}

function Add-BillOfMaterialsEntry {
    param(
        [string]$Name,
        [string]$Publisher,
        [string]$SourceUri,
        [string]$ValidationScript,
        [string]$Version
    );

    $rs = [char]::ConvertFromUtf32(30);

    Add-Content `
        -Path ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'BillOfMaterials.log')) `
        -Value "${Name}${rs}${Publisher}${rs}${SourceUri}${rs}${ValidationScript}${rs}${Version}";
}
function Add-WindowsMachinePath {
    param (
        [string]$Path
    );

    Set-WindowsMachineVariable `
        -Name 'Path' `
        -Value "$(Get-WindowsMachineVariable -Name 'Path');$((Get-Item -Path $Path).FullName)";
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
            (Get-Item -Path ([IO.Path]::Combine([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $ToolName), $Version)) |
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
        Sort-Object -Descending { ([version]$_.Version); } |
        Select-Object `
            -ExpandProperty 'Files' `
            -Property 'Version' |
        Where-Object { (
            ($Architecture -eq $_.Architecture) -and
            ($Platform -eq $_.Platform)
        ); } |
        Select-Object -First 1;
}
function Get-WindowsMachineVariable {
    param(
        [switch]$Expand,
        [string]$Name
    );

    Get-WindowsVariable `
        -Expand:$Expand `
        -Name $Name `
        -Path 'HKLM:/SYSTEM/CurrentControlSet/Control/Session Manager/Environment';
}
function Get-WindowsUserVariable {
    param(
        [switch]$Expand,
        [string]$Name
    );

    Get-WindowsVariable `
        -Expand:$Expand `
        -Name $Name `
        -Path 'HKCU:/Environment';
}
function Get-WindowsVariable {
    param(
        [switch]$Expand,
        [string]$Name,
        [string]$Path
    );

    $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames;

    if ($Expand) {
        $options = [Microsoft.Win32.RegistryValueOptions]::None;
    }

    if ('Env:' -eq $Path) {
        return [Linq.Enumerable]::Single(
            (Get-ChildItem -Path 'Env:'),
            [Func[object, bool]] {
                param(
                    [Collections.DictionaryEntry]$entry
                );

                return ($Name -eq $entry.Key);
            }
        ).Value;
    }
    else {
        return (Get-Item -Path $Path).GetValue(
                $Name,
                '',
                $options
            );
    }
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

    $sourceUri = 'https://aka.ms/downloadazcopy-v10-windows';

    Add-BillOfMaterialsEntry `
        -Name 'AzCopy' `
        -Publisher 'Microsoft' `
        -SourceUri $sourceUri `
        -ValidationScript '([version](azcopy --version).Split('' '')[2]).Major;' `
        -Version '10';

    $azCopyPath = [IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'azcopy');
    $installerFileName = "azcopy_windows_amd64.zip";
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerFileName)),
            $sourceUri
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

    Add-WindowsMachinePath -Path ((Get-ChildItem -Path "${azCopyPath}/*" | Select-Object -First 1).FullName);
}
function Install-BicepCli {
    param(
        [HttpService]$HttpService
    );

    $sourceUri = 'https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe';

    Add-BillOfMaterialsEntry `
        -Name 'Bicep' `
        -Publisher 'Microsoft' `
        -SourceUri $sourceUri `
        -ValidationScript '(bicep --version).Split('' '')[3];' `
        -Version 'latest';

    $bicepPath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'bicep'))).FullName;

    $HttpService.DownloadFile(
            ([IO.Path]::Combine($bicepPath, 'bicep.exe')),
            $sourceUri
        ) |
        Out-Null;
    Add-WindowsMachinePath -Path $bicepPath;
}
function Install-DockerCompose {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    $cliPluginsPath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path "${Env:ProgramData}/docker/cli-plugins").FullName;
    $installerData = [Linq.Enumerable]::Single(
            $HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [GitHubReleasesManifest],
                'https://api.github.com/repos/docker/compose/releases/latest'
            ).Assets,
            [Func[object, bool]] {
                param(
                    [GitHubReleasesAsset]$asset
                );

                return $asset.Name.EndsWith('windows-x86_64.exe');
            }
        );

    Add-BillOfMaterialsEntry `
        -Name 'Docker Compose' `
        -Publisher 'Docker' `
        -SourceUri ($installerData.BrowserDownloadUrl) `
        -ValidationScript '(docker compose version).Split('' '')[3].Substring(1);' `
        -Version 'latest';
    $HttpService.DownloadFile(
            ([IO.Path]::Combine($cliPluginsPath, 'docker-compose.exe')),
            $installerData.BrowserDownloadUrl
        ) |
        Out-Null;
}
function Install-DockerCredentialHelpers {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    $installerData = [Linq.Enumerable]::Single(
            $HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [GitHubReleasesManifest],
                'https://api.github.com/repos/docker/docker-credential-helpers/releases/latest'
            ).Assets,
            [Func[object, bool]] {
                param(
                    [GitHubReleasesAsset]$asset
                );

                return $asset.Name.EndsWith('windows-amd64.exe');
            }
        );

    Add-BillOfMaterialsEntry `
        -Name 'Docker Credential Helpers' `
        -Publisher 'Docker' `
        -SourceUri ($installerData.BrowserDownloadUrl) `
        -ValidationScript '(docker-credential-wincred version).Split('' '')[2].Substring(1);' `
        -Version 'latest';
    $HttpService.DownloadFile(
            ([IO.Path]::Combine("${Env:SystemRoot}/System32", 'docker-credential-wincred.exe')),
            $installerData.BrowserDownloadUrl
        ) |
        Out-Null;
}
function Install-DockerTools {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$Version
    );

    if ([string]::IsNullOrEmpty($Version) -or ('latest' -eq $Version)) {
        $Version = $HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [MobyReleasesManifest],
                'https://api.github.com/repos/moby/moby/releases/latest'
            ).TagName.Substring(1);
    }

    $sourceFileName = "docker-${Version}.zip";
    $sourceUri = "https://download.docker.com/win/static/stable/x86_64/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -Name 'Docker Community Edition' `
        -Publisher 'Docker' `
        -SourceUri $sourceUri `
        -ValidationScript '(docker --version).Split('' '')[2].Split('','')[0];' `
        -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $sourceFileName)),
            $sourceUri
        );
    $installerFolderPath = ${Env:AGENT_TOOLSDIRECTORY};

    & "${Env:ProgramFiles}/7-Zip/7z.exe" `
        x $installerFilePath `
        "-o${installerFolderPath}" `
        -y |
        Out-Null;

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }

    $installerFileName = 'install-docker-ce.ps1';
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerFileName)),
            "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/${installerFileName}"
        );

    & $installerFilePath `
        -DockerDPath ((Get-Item -Path "${installerFolderPath}/docker/dockerd.exe").FullName) `
        -DockerPath ((Get-Item -Path "${installerFolderPath}/docker/docker.exe").FullName) |
        Out-Null;
    Start-Sleep -Seconds 3;

    if (Test-Path -Path $installerFilePath) {
        Remove-Item `
            -Force `
            -Path $installerFilePath;
    }

    New-Item `
        -ItemType 'SymbolicLink' `
        -Path "${Env:SystemRoot}/SysWOW64/docker.exe" `
        -Target "${Env:SystemRoot}/System32/docker.exe" |
        Out-Null;
    Install-DockerCompose `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Install-DockerCredentialHelpers `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Update-WindowsVariables;
    @(
        'mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022',
        'mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022',
        'mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022',
        'mcr.microsoft.com/windows/nanoserver:ltsc2022',
        'mcr.microsoft.com/windows/servercore:ltsc2022'
    ) | ForEach-Object {
            docker pull $_;
        };
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
function Install-DotNetTools {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    $dotNetToolsPath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'dotnet'))).FullName;
    $installerFileName = 'dotnet-install.ps1';
    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerFileName)),
            "https://dot.net/v1/${installerFileName}"
        );
    $sdkDirectoryPath = ([IO.Path]::Combine(${Env:ProgramFiles}, 'dotnet'));

    Add-WindowsMachinePath -Path $dotNetToolsPath;
    Set-WindowsMachineVariable `
        -Name 'DOTNET_ADD_GLOBAL_TOOLS_TO_PATH' `
        -Value '0';
    Set-WindowsMachineVariable `
        -Name 'DOTNET_CLI_TELEMETRY_OPTOUT' `
        -Value '1';
    Set-WindowsMachineVariable `
        -Name 'DOTNET_MULTILEVEL_LOOKUP' `
        -Value '0';
    Set-WindowsMachineVariable `
        -Name 'DOTNET_NOLOGO' `
        -Value '1';
    Set-WindowsMachineVariable `
        -Name 'DOTNET_SKIP_FIRST_TIME_EXPERIENCE' `
        -Value '1';
    Update-WindowsVariables;
    @(
        'Azure.Bicep.RegistryModuleTool',
        'dotnet-coverage',
        'dotnet-ef',
        'dotnet-format',
        'dotnet-sonarscanner',
        'Microsoft.Playwright.CLI',
        'nbgv'
    ) | ForEach-Object {
            dotnet tool install $_ --tool-path $dotNetToolsPath;
        };
    @(
        '3.1.*',
        '6.0.*'
    ) | ForEach-Object {
            Install-DotNetSdk `
                -HttpService $HttpService `
                -InstallerFilePath $installerFilePath `
                -JsonSerializerOptions $JsonSerializerOptions `
                -SdkDirectoryPath $sdkDirectoryPath `
                -Version $_;
        };
}
function Install-GitForWindows {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    $installerData = [Linq.Enumerable]::Single(
            $HttpService.GetJsonAsT(
                $JsonSerializerOptions,
                [GitHubReleasesManifest],
                'https://api.github.com/repos/git-for-windows/git/releases/latest'
            ).Assets,
            [Func[object, bool]] {
                param(
                    [GitHubReleasesAsset]$asset
                );

                return $asset.Name.EndsWith('64-bit.exe');
            }
        );

    Add-BillOfMaterialsEntry `
        -Name 'Git' `
        -Publisher 'Git for Windows' `
        -SourceUri $installerData.BrowserDownloadUrl `
        -ValidationScript '(git --version).Split('' '')[2];' `
        -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerData.Name)),
            $installerData.BrowserDownloadUrl
        );
    $installerOutputPath = [IO.Path]::Combine(${Env:ProgramFiles}, 'Git');
    $process = Start-Process `
        -ArgumentList @(
            '/ALLUSERS',
            '/CLOSEAPPLICATIONS',
            '/COMPONENTS=gitlfs',
            "/DIR=`"${installerOutputPath}`"",
            '/NOCANCEL',
            '/NORESTART',
            '/RESTARTAPPLICATIONS',
            '/SP-',
            '/VERYSILENT',
            '/o:BashTerminalOption=ConHost',
            '/o:EnableSymlinks=Enabled',
            '/o:PathOption=CmdTools'
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

    Set-WindowsMachineVariable `
        -Name 'GCM_INTERACTIVE' `
        -Value 'Never';
    Update-WindowsVariables;
    git config --system --add safe.directory "*";
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "${installerOutputPath}/etc/ssh/ssh_known_hosts" | Out-Null;
    ssh-keyscan -t rsa ssh.dev.azure.com >> "${installerOutputPath}/etc/ssh/ssh_known_hosts" | Out-Null;
}
function Install-GitHubActionsTool {
    param(
        [string]$Architecture,
        [HttpService]$HttpService,
        [string]$Platform,
        [string]$ToolName,
        [string]$ValidationScript,
        [string]$Version
    );

    $installerData = Get-GitHubActionsVersionsManifest `
        -Architecture $Architecture `
        -HttpService $HttpService `
        -Platform $Platform `
        -ToolName $ToolName `
        -Version $Version;

    Add-BillOfMaterialsEntry `
        -Name "${ToolName}-${Architecture}-${Platform}-$($installerData.Version)" `
        -Publisher 'GitHub' `
        -SourceUri ($installerData.DownloadUri) `
        -ValidationScript "Push-Location -Path '${Env:AGENT_TOOLSDIRECTORY}/${ToolName}/$($installerData.Version)/${Architecture}'; try { ${ValidationScript} } finally { Pop-Location; }" `
        -Version ($installerData.Version);

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerData.FileName)),
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
    param(
        [HttpService]$HttpService
    );

    $gitHubActionsTools = @(
        @{
            Architectures = @( 'x64' );
            DefaultArchitecture = $null;
            DefaultVersion = $null;
            Name = 'Go';
            ValidationScript = '(./bin/go.exe version).Split('' '')[2].Substring(2);';
            Versions = @(
                '1.18.*',
                '1.19.*',
                '1.20.*'
            );
        },
        @{
            Architectures = @( 'x64' );
            DefaultArchitecture = $null;
            DefaultVersion = $null;
            Name = 'Node';
            ValidationScript = '(./node.exe --version).Substring(1);';
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
            DefaultVersion = $null;
            Name = 'Python';
            ValidationScript = '(./python.exe --version).Split('' '')[1];';
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
                        -HttpService $HttpService `
                        -Platform 'win32' `
                        -ToolName ($tool.Name) `
                        -ValidationScript ($tool.ValidationScript) `
                        -Version $version;
                }
            }
        };
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
                Add-WindowsMachinePath -Path "${toolPath}/bin";
            }

            if ('Python' -eq $toolName) {
                Add-WindowsMachinePath -Path $toolPath;
                Add-WindowsMachinePath -Path "${toolPath}/Scripts";
            }
        };
    Update-WindowsVariables;
}
function Install-GoogleChrome {
    param(
        [HttpService]$HttpService
    );

    $sourceFileName = 'googlechromestandaloneenterprise64.msi';
    $sourceUri = "https://dl.google.com/tag/s/dl/chrome/install/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -Name 'Chrome' `
        -Publisher 'Google' `
        -SourceUri $sourceUri `
        -ValidationScript '(Get-Item -Path "${Env:ProgramFiles}/Google/Chrome/Application/chrome.exe").VersionInfo.ProductVersion;' `
        -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $sourceFileName)),
            $sourceUri
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
        },
        @{
            Name = 'DisableAutoUpdateChecksCheckboxValue';
            Value = 1;
        },
        @{
            Name = 'UpdateDefault';
            Value = 0;
        },
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
        };
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

    $sourceUri = "https://download.mozilla.org/?lang=en-US&product=firefox-${Version}&os=win64";

    Add-BillOfMaterialsEntry `
            -Name 'Firefox' `
            -Publisher 'Mozilla' `
            -SourceUri $sourceUri `
            -ValidationScript '(& "${Env:ProgramFiles}/Mozilla Firefox/firefox.exe" --version | more).Split('' '')[2];' `
            -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'Firefox_Windows_x64.exe')),
            $sourceUri
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

    $sourceUri = "https://nodejs.org/dist/v${Version}/node-v${Version}-x64.msi";

    Add-BillOfMaterialsEntry `
        -Name 'Node.js' `
        -Publisher 'OpenJS Foundation' `
        -SourceUri $sourceUri `
        -ValidationScript '(node --version).Substring(1);' `
        -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, 'NodeJs_Windows_x64.msi')),
            $sourceUri
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

    $cachePath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path 'C:/npm/cache').FullName;
    $prefixPath = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path 'C:/npm/prefix').FullName;

    Add-WindowsMachinePath -Path $prefixPath;
    Set-WindowsMachineVariable `
        -Name 'NPM_CONFIG_PREFIX' `
        -Value $prefixPath;
    Update-WindowsVariables;

    npm config set cache $cachePath --global;
    npm config set registry https://registry.npmjs.org/;
}
function Install-OpenSsl {
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    $installerData = $HttpService.GetJsonAsT(
            $JsonSerializerOptions,
            [OpenSslReleaseManifest],
            'https://raw.githubusercontent.com/slproweb/opensslhashes/master/win32_openssl_hashes.json'
        ).
        Files.
        GetEnumerator() |
        Where-Object {
            ('INTEL' -eq $_.Value.Architecture) -and
            (64 -eq $_.Value.Bits) -and
            ('exe' -eq $_.Value.InstallerType) -and
            ($false -eq $_.Value.IsLight)
        } |
        Sort-Object -Descending { $_.Value.Version } |
        Select-Object -First 1;

    Add-BillOfMaterialsEntry `
            -Name 'OpenSSL' `
            -Publisher 'Shining Light Productions' `
            -SourceUri ($installerData.Value.Uri) `
            -ValidationScript '(openssl version).Split('' '')[1];' `
            -Version 'latest';

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $installerData.Key)),
            $installerData.Value.Uri
        );
    $installerOutputPath = [IO.Path]::Combine(${Env:ProgramFiles}, 'OpenSSL');
    $process = Start-Process `
        -ArgumentList @(
            '/ALLUSERS',
            "/DIR=`"${installerOutputPath}`"",
            '/NORESTART',
            '/SP-',
            '/SUPPRESSMSGBOXES',
            '/VERYSILENT'
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

    Add-WindowsMachinePath -Path ([IO.Path]::Combine($installerOutputPath, 'bin'));
    Update-WindowsVariables;
}
function Install-Pipx {
    $pipxBin = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::Combine(${Env:ProgramFiles(x86)}, 'pipx_bin'))).FullName;
    $pipxHome = (New-Item `
        -Force `
        -ItemType 'Directory' `
        -Path ([IO.Path]::Combine(${Env:ProgramFiles(x86)}, 'pipx'))).FullName;

    Set-WindowsMachineVariable `
        -Name 'PIPX_BIN_DIR' `
        -Value $pipxBin;
    Set-WindowsMachineVariable `
        -Name 'PIPX_HOME' `
        -Value $pipxHome;

    pip install pipx;

    Add-WindowsMachinePath -Path $pipxBin;
    Update-WindowsVariables;
}
function Install-PostgresSql {
    param(
        [HttpService]$HttpService,
        [string]$Version
    );

    $sourceFileName = "postgresql-${Version}-windows-x64.exe";
    $sourceUri = "https://get.enterprisedb.com/postgresql/${sourceFileName}";

    Add-BillOfMaterialsEntry `
        -Name 'PostgreSQL' `
        -Publisher 'EDB' `
        -SourceUri $sourceUri `
        -ValidationScript '(& "${Env:PGBIN}/psql" --version).Split('' '')[2];' `
        -Version ($Version.Split('-')[0]);

    $installerFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, $sourceFileName)),
            $sourceUri
        );
    $process = Start-Process `
        -ArgumentList @(
            '--enable_acledit', '1',
            '--install_runtimes', 'no',
            '--mode', 'unattended',
            '--unattendedmodeui', 'none'
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

    $pgSqlRoot = [IO.DirectoryInfo]::new((Get-CimInstance `
        -ClassName 'Win32_Service' `
        -Filter "Name LIKE 'postgresql-%'").PathName.Split('"')[5]).Parent.FullName;

    Set-WindowsMachineVariable `
        -Name 'PGBIN' `
        -Value ([IO.Path]::Combine($pgSqlRoot, 'bin'));
    Set-WindowsMachineVariable `
        -Name 'PGDATA' `
        -Value ([IO.Path]::Combine($pgSqlRoot, 'data'));
    Set-WindowsMachineVariable `
        -Name 'PGROOT' `
        -Value $pgSqlRoot;

    $service = Get-Service -Name 'postgresql*';
    $service | Set-Service -StartupType ([ServiceProcess.ServiceStartMode]::Disabled);
    $service | Stop-Service;
    $service.WaitForStatus('Stopped', '00:00:53');
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
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions,
        [string]$Name,
        [string]$Publisher,
        [string]$SourceUri
    );

    if ([string]::IsNullOrEmpty($SourceUri)) {
        $HttpService.Get(
                [Action[Net.Http.HttpResponseMessage]] {
                    param([Net.Http.HttpResponseMessage]$responseMessage);

                    $htmlFile = New-Object -ComObject 'HTMLFile';
                    $htmlFile.Write([Text.Encoding]::Convert(
                            [Text.Encoding]::UTF8,
                            [Text.Encoding]::Unicode,
                            $responseMessage.Content.ReadAsStream().ToArray()
                        ));
                    $json = [Text.Json.JsonSerializer]::Deserialize(
                            ([string]$htmlFile.GetElementsByClassName('jiContent')[0].innerHtml),
                            [Collections.Generic.Dictionary[string,Text.Json.JsonElement]],
                            $JsonSerializerOptions
                        );
                    ([ref]$SourceUri).Value = "$($json['AssetUri'].GetString())/$($json['ExtensionProperties'].GetProperty('Microsoft.VisualStudio.Services.Payload.FileName').GetString())";
                },
                "https://marketplace.visualstudio.com/items?itemName=${Publisher}.${Name}"
            );
    }

    $extensionFilePath = $HttpService.DownloadFile(
            ([IO.Path]::Combine(${Env:AGENT_TOOLSDIRECTORY}, "${Publisher}.${Name}.vsix")),
            $SourceUri
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
    param(
        [HttpService]$HttpService,
        [Text.Json.JsonSerializerOptions]$JsonSerializerOptions
    );

    @(
        @{
            DownloadUri = 'https://download.microsoft.com/download/b/7/5/b75f1ed1-1e35-4f8d-b39f-77189c54ce01/Microsoft.DataTools.AnalysisServices.vsix';
            Name = 'MicrosoftAnalysisServicesModelingProjects2022';
            Publisher = 'ProBITools';
        },
        @{
            DownloadUri = 'https://download.microsoft.com/download/f/3/7/f37248df-84b3-4306-918f-2de56481299f/Microsoft.DataTools.ReportingServices.vsix';
            Name = 'MicrosoftReportProjectsforVisualStudio2022';
            Publisher = 'ProBITools';
        },
        @{
            DownloadUri = $null;
            Name = 'MicrosoftVisualStudio2022InstallerProjects';
            Publisher = 'VisualStudioClient';
        },
        @{
            DownloadUri = $null;
            Name = 'WixToolsetVisualStudio2022Extension';
            Publisher = 'WixToolset';
        }
    ) |
        ForEach-Object {
            Install-VisualStudioExtension `
                -HttpService $HttpService `
                -JsonSerializerOptions $JsonSerializerOptions `
                -Name $_.Name `
                -Publisher $_.Publisher `
                -SourceUri $_.DownloadUri;
        }
}
function Set-WindowsMachineVariable {
    param(
        [string]$Name,
        [string]$Type,
        [string]$Value
    );

    $arguments = @{
        Force = $true;
        Name = $Name;
        Path = 'HKLM:/SYSTEM/CurrentControlSet/Control/Session Manager/Environment';
        Value = $Value;
    };

    if (-not [string]::IsNullOrEmpty($Type)) {
        $arguments.PropertyType = $type;
    }

    New-ItemProperty @arguments | Out-Null;
}
function Set-WindowsProcessVariable {
    param(
        [string]$Name,
        [string]$Value
    );

    Set-Item `
        -Force `
        -Path "Env:${Name}" `
        -Value $Value |
        Out-Null;
}
function Update-WindowsVariables {
    $originalArchitecture = ${Env:PROCESSOR_ARCHITECTURE};
    $originalPsModulePath = ${Env:PSModulePath};
    $originalUserName = ${Env:USERNAME};
    $pathEntries = ([string[]]@());

    # 0) process
    Get-ChildItem -Path 'Env:' |
        Select-Object -ExpandProperty 'Key' |
            ForEach-Object {
                Set-WindowsProcessVariable `
                    -Name $_ `
                    -Value ([Environment]::GetEnvironmentVariable($_, [EnvironmentVariableTarget]::Process));
            }

    # 1) machine
    Get-Item -Path 'HKLM:/SYSTEM/CurrentControlSet/Control/Session Manager/Environment' |
        Select-Object -ExpandProperty 'Property' |
            ForEach-Object {
                $value = Get-WindowsMachineVariable `
                    -Expand `
                    -Name $_;

                if ('Path' -eq $_) {
                    $pathEntries += $value.Split(';');
                }
                else {
                    Set-WindowsProcessVariable `
                        -Name $_ `
                        -Value $value;
                }
            }

    # 2) user
    if ($originalUserName -notin @('SYSTEM', "${Env:COMPUTERNAME}$")) {
        Get-Item -Path 'HKCU:/Environment' |
            Select-Object -ExpandProperty 'Property' |
                ForEach-Object {
                    $value = Get-WindowsUserVariable `
                        -Expand `
                        -Name $_;

                        if ('Path' -eq $_) {
                            $pathEntries += $value.Split(';');
                        }
                        else {
                            Set-WindowsProcessVariable `
                                -Name $_ `
                                -Value $value;
                        }
                }
    }

    ${Env:Path} = (($pathEntries | Select-Object -Unique) -join ';');
    ${Env:PROCESSOR_ARCHITECTURE} = $originalArchitecture;
    ${Env:PSModulePath} = $originalPsModulePath;

    if ($originalUserName) {
        ${Env:USERNAME} = $originalUserName;
    }
}

Set-StrictMode -Version 'Latest';

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
    $httpClient.DefaultRequestHeaders.Add('User-Agent', 'bytrc-automation');
    $httpService = [HttpService]::new($httpClient);
    $jsonSerializerOptions = [Text.Json.JsonSerializerOptions]::new();
    $jsonSerializerOptions.PropertyNamingPolicy = [Text.Json.JsonNamingPolicy]::CamelCase;

    Install-AzureCliExtensions;
    Install-AzureCopy -HttpService $httpService;
    Install-BicepCli -HttpService $httpService;
    Install-DockerTools `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions `
        -Version 'latest';
    Install-DotNetTools `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Install-GitHubActionsTools -HttpService $httpService;
    Install-GoogleChrome -HttpService $httpService;
    Install-MozillaFirefox `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions `
        -Version 'latest';
    Install-NodeJs `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions `
        -Version 'latest';
    Install-OpenSsl `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Install-GitForWindows `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
    Install-PostgresSql `
        -HttpService $httpService `
        -Version '15.3-1';
    Install-PowerShellModules;
    Install-Pipx;
    Install-VisualStudioExtensions `
        -HttpService $httpService `
        -JsonSerializerOptions $jsonSerializerOptions;
}
catch {
    if ($null -ne $httpClient) {
        $httpClient.Dispose();
    }

    throw;
}
