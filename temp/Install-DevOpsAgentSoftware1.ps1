[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
);

class BaseHttpClient {
    [Net.Http.HttpClient]$HttpClient;

    BaseHttpClient([Net.Http.HttpClient]$httpClient) {
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
class ReleaseFile {
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
class VersionsManifest {
    [ReleaseFile[]]$Files;
    [Text.Json.Serialization.JsonPropertyName('stable')]
    [bool]$IsStable
    [Text.Json.Serialization.JsonPropertyName('release_url')]
    [string]$ReleaseUri;
    [string]$Version;
}

function Get-GitHubActionsVersionsManifest {
    param(
        [string]$Architecture,
        [BaseHttpClient]$GitActionsContentService,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$ToolName,
        [string]$Version
    );

    return $GitActionsContentService.GetJsonAsT(
            $null,
            [VersionsManifest[]],
            "${ToolName}-versions/main/versions-manifest.json"
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
function Install-GitHubActionsTool {
    param(
        [string]$Architecture,
        [BaseHttpClient]$GitActionsContentService,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$ToolName,
        [string]$Version
    );

    $installerData = Get-GitHubActionsVersionsManifest `
        -Architecture $Architecture `
        -GitActionsContentService $GitActionsContentService `
        -LogFilePath $LogFilePath `
        -Platform $Platform `
        -ToolName $ToolName `
        -Version $Version;
    $installerFilePath = $GitActionsContentService.DownloadFile(
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
function Install-Go {
    param(
        [string]$Architecture,
        [BaseHttpClient]$GitActionsContentService,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$Version
    );

    Install-GitHubActionsTool `
        -Architecture $Architecture `
        -GitActionsContentService $GitActionsContentService `
        -LogFilePath $LogFilePath `
        -Platform $Platform `
        -ToolName 'go' `
        -Version $Version;
}
function Install-Node {
    param(
        [string]$Architecture,
        [BaseHttpClient]$GitActionsContentService,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$Version
    );

    Install-GitHubActionsTool `
        -Architecture $Architecture `
        -GitActionsContentService $GitActionsContentService `
        -LogFilePath $LogFilePath `
        -Platform $Platform `
        -ToolName 'node' `
        -Version $Version;
}
function Install-Python {
    param(
        [string]$Architecture,
        [BaseHttpClient]$GitActionsContentService,
        [string]$LogFilePath,
        [string]$Platform,
        [string]$Version
    );

    Install-GitHubActionsTool `
        -Architecture $Architecture `
        -GitActionsContentService $GitActionsContentService `
        -LogFilePath $LogFilePath `
        -Platform $Platform `
        -ToolName 'python' `
        -Version $Version;
}
function Install-VisualStudio {
    param(
        [BaseHttpClient]$AkaMsService,
        [string[]]$Components,
        [string]$Edition,
        [string]$LogFilePath,
        [string]$Version
    );

    $bootstrapperArgumentList = @(
        '--addProductLang', 'en-US',
        '--includeRecommended',
        '--nickname', 'DevOps',
        '--norestart',
        '--quiet'
    );
    $bootstrapperFileName = "vs_${Edition}.exe";
    $bootstrapperFilePath = $AkaMsService.DownloadFile(
            ([IO.Path]::Combine((Get-Location), $bootstrapperFileName)),
            "vs/${Version}/release/${bootstrapperFileName}"
        );

    $Components | ForEach-Object {
        $bootstrapperArgumentList += '--add';
        $bootstrapperArgumentList += $_;
    }

    $process = Start-Process `
        -ArgumentList $bootstrapperArgumentList `
        -FilePath $bootstrapperFilePath `
        -PassThru `
        -Wait;

    if ((0 -ne $process.ExitCode) -and (3010 -ne $process.ExitCode)) {
        throw "Non-zero exit code returned by the process: $($process.ExitCode).";
    }

    Start-Sleep -Seconds 3;

    if (Test-Path -Path $bootstrapperFilePath) {
        Remove-Item `
            -Force `
            -Path $bootstrapperFilePath;
    }
}

[Net.Http.HttpClient]$akaMsHttpClient = $null;
[Net.Http.HttpClient]$gitActionsContentHttpClient = $null;

try {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;
    [Net.ServicePointManager]::SecurityProtocol = (
        [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls13
    );

    $akaMsHttpClient = [Net.Http.HttpClient]::new();
    $akaMsHttpClient.BaseAddress = 'https://aka.ms/';
    $akaMsService = [BaseHttpClient]::new($akaMsHttpClient);
    $gitActionsContentHttpClient = [Net.Http.HttpClient]::new();
    $gitActionsContentHttpClient.BaseAddress = 'https://raw.githubusercontent.com/actions/';
    $gitActionsContentService = [BaseHttpClient]::new($gitActionsContentHttpClient);

    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop;';
    Add-Content `
        -Path ($profile.AllUsersAllHosts) `
        -Value '$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue;';
    @(
        '1.18.*',
        '1.19.*',
        '1.20.*'
    ) | ForEach-Object {
        Install-Go `
            -Architecture 'x64' `
            -GitActionsContentService $gitActionsContentService `
            -LogFilePath $LogFilePath `
            -Platform 'win32' `
            -Version $_;
    }
    @(
        '14.*',
        '16.*',
        '18.*'
    ) | ForEach-Object {
        Install-Node `
            -Architecture 'x64' `
            -GitActionsContentService $gitActionsContentService `
            -LogFilePath $LogFilePath `
            -Platform 'win32' `
            -Version $_;
    }
    @(
        '3.7.*',
        '3.8.*',
        '3.9.*',
        '3.10.*'
        '3.11.*'
    ) | ForEach-Object {
        Install-Python `
            -Architecture 'x64' `
            -GitActionsContentService $gitActionsContentService `
            -LogFilePath $LogFilePath `
            -Platform 'win32' `
            -Version $_;
        Install-Python `
            -Architecture 'x86' `
            -GitActionsContentService $gitActionsContentService `
            -LogFilePath $LogFilePath `
            -Platform 'win32' `
            -Version $_;
    }
    Install-VisualStudio `
        -AkaMsService $akaMsService `
        -Components @(
            'Component.Dotfuscator',
            'Microsoft.Component.Azure.DataLake.Tools',
            'Microsoft.Net.Component.4.5.2.TargetingPack',
            'Microsoft.Net.Component.4.6.TargetingPack',
            'Microsoft.Net.Component.4.6.1.TargetingPack',
            'Microsoft.Net.Component.4.6.2.TargetingPack',
            'Microsoft.Net.Component.4.7.TargetingPack',
            'Microsoft.Net.Component.4.7.1.TargetingPack',
            'Microsoft.Net.Component.4.7.2.TargetingPack',
            'Microsoft.Net.Component.4.8.TargetingPack',
            'Microsoft.Net.Component.4.8.1.SDK',
            'Microsoft.Net.Component.4.8.1.TargetingPack',
            'Microsoft.VisualStudio.Component.AspNet',
            'Microsoft.VisualStudio.Component.AspNet45',
            'Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools',
            'Microsoft.VisualStudio.Component.AzureDevOps.OfficeIntegration',
            'Microsoft.VisualStudio.Component.Debugger.JustInTime',
            'Microsoft.VisualStudio.Component.DotNetModelBuilder',
            'Microsoft.VisualStudio.Component.DslTools',
            'Microsoft.VisualStudio.Component.EntityFramework',
            'Microsoft.VisualStudio.Component.LinqToSql',
            'Microsoft.VisualStudio.Component.PortableLibrary',
            'Microsoft.VisualStudio.Component.SecurityIssueAnalysis',
            'Microsoft.VisualStudio.Component.Sharepoint.Tools',
            'Microsoft.VisualStudio.Component.SQL.SSDT',
            'Microsoft.VisualStudio.Component.WebDeploy',
            'Microsoft.VisualStudio.Component.Windows10SDK.20348',
            'Microsoft.VisualStudio.Component.Windows11SDK.22621',
            'Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices',
            'Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools',
            'Microsoft.VisualStudio.ComponentGroup.Web.CloudTools',
            'Microsoft.VisualStudio.Workload.Azure',
            'Microsoft.VisualStudio.Workload.Data',
            'Microsoft.VisualStudio.Workload.DataScience',
            'Microsoft.VisualStudio.Workload.ManagedDesktop',
            'Microsoft.VisualStudio.Workload.NativeCrossPlat',
            'Microsoft.VisualStudio.Workload.NativeDesktop',
            'Microsoft.VisualStudio.Workload.NativeMobile',
            'Microsoft.VisualStudio.Workload.NetCrossPlat',
            'Microsoft.VisualStudio.Workload.NetWeb',
            'Microsoft.VisualStudio.Workload.Node',
            'Microsoft.VisualStudio.Workload.Office',
            'Microsoft.VisualStudio.Workload.Python',
            'Microsoft.VisualStudio.Workload.Universal',
            'Microsoft.VisualStudio.Workload.VisualStudioExtension',
            'wasm.tools'
        ) `
        -Edition 'Enterprise' `
        -LogFilePath $LogFilePath `
        -Version '17';
}
catch {
    if ($null -ne $akaMsHttpClient) {
        $akaMsHttpClient.Dispose();
    }

    if ($null -ne $gitActionsContentHttpClient) {
        $gitActionsContentHttpClient.Dispose();
    }

    throw;
}
