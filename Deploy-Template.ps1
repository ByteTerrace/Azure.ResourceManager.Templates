[CmdletBinding(DefaultParameterSetName = 'Template-SpecId')]
param(
    [Parameter(Mandatory = $false)]
    [string]$Mode = 'Incremental',
    [Parameter(Mandatory = $false)]
    [string]$Name = '',
    [Parameter(Mandatory = $false)]
    [string]$Parameters = '',
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionNameOrId = '',
    [Parameter(Mandatory = $true, ParameterSetName = 'Template-FilePath')]
    [string]$TemplateFilePath = '',
    [Parameter(Mandatory = $true, ParameterSetName = 'Template-SpecId')]
    [string]$TemplateSpecId = '',
    [Parameter(Mandatory = $true, ParameterSetName = 'Template-Uri')]
    [string]$TemplateUri = '',
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = ''
)

if ([string]::IsNullOrEmpty($WorkingDirectory)) {
    $WorkingDirectory = '.';
}

Push-Location -Path $WorkingDirectory;

try {
    if ([string]::IsNullOrEmpty($Name)) {
        $Name = ${Env:USERNAME};
    }

    $arguments = @(
        'deployment', 'group', 'create',
        '--mode', $Mode,
        '--name', $Name,
        '--resource-group', $ResourceGroupName
    );

    if (-not [string]::IsNullOrEmpty($Parameters)) {
        $arguments += @('--parameters', $Parameters)
    }

    if (-not [string]::IsNullOrEmpty($SubscriptionNameOrId)) {
        $arguments += @('--subscription', $SubscriptionNameOrId)
    }

    if (-not [string]::IsNullOrEmpty($TemplateFilePath)) {
        $arguments += @('--template-file', $TemplateFilePath);
    }

    if (-not [string]::IsNullOrEmpty($TemplateSpecId)) {
        $arguments += @('--template-spec', $TemplateSpecId);
    }

    if (-not [string]::IsNullOrEmpty($TemplateUri)) {
        $arguments += @('--template-uri', $TemplateUri);
    }

    if ($WhatIf) {
        $arguments += '--what-if';
    }

    az @arguments;
}
finally {
    Pop-Location;
}
