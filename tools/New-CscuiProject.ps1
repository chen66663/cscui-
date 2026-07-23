<#
.SYNOPSIS
    Creates a cscui application from a maintained scaffold template.

.DESCRIPTION
    The command is safe for local use and non-interactive CI. Project names
    are validated as single path segments, templates are resolved from the
    repository, and an existing destination is never overwritten.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$Name,
    [string]$Destination,
    [string]$Template,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptRoot '..')).Path
$templatesRoot = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'scaffold\templates')).Path
$isCi = $env:CI -and $env:CI -notmatch '^(0|false|no)$'
$interactive = -not ($NonInteractive -or $isCi)

function Read-Value {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$Default
    )

    if (-not $interactive) {
        return $Default
    }

    if ([string]::IsNullOrEmpty($Default)) {
        return (Read-Host $Prompt)
    }

    $answer = Read-Host "$Prompt (default: $Default)"
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $Default
    }
    return $answer
}

function Replace-Token {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$Value
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path, $encoding)
    [System.IO.File]::WriteAllText($Path, $content.Replace($Token, $Value), $encoding)
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Required source directory was not found: $Source"
    }
    New-Item -ItemType Directory -LiteralPath $DestinationPath -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $DestinationPath -Recurse -Force
    }
}

try {
    $availableTemplates = @(
        Get-ChildItem -LiteralPath $templatesRoot -Directory |
            Sort-Object -Property Name |
            Select-Object -ExpandProperty Name
    )
    if ($availableTemplates.Count -eq 0) {
        throw "No scaffold templates were found under $templatesRoot"
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Read-Value -Prompt 'Project name (required)' -Default $null
    }
    $Name = if ($null -eq $Name) { '' } else { $Name.Trim() }
    if ($Name -notmatch '^[A-Za-z][A-Za-z0-9_-]{0,63}$') {
        throw 'Project name must start with a letter and contain only letters, digits, hyphens, or underscores (1-64 characters).'
    }
    $reservedNames = @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9')
    if ($reservedNames -contains $Name.ToUpperInvariant()) {
        throw "Project name '$Name' is reserved by Windows."
    }

    $defaultDestination = Split-Path -Parent $repoRoot
    if ([string]::IsNullOrWhiteSpace($Destination)) {
        $Destination = Read-Value -Prompt 'Destination directory' -Default $defaultDestination
    }
    if ([string]::IsNullOrWhiteSpace($Destination)) {
        throw 'Destination directory cannot be empty.'
    }
    if (Test-Path -LiteralPath $Destination) {
        if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
            throw "Destination is not a directory: $Destination"
        }
    } elseif ($PSCmdlet.ShouldProcess($Destination, 'Create destination directory')) {
        New-Item -ItemType Directory -LiteralPath $Destination -Force | Out-Null
    } else {
        return
    }
    $destinationRoot = (Resolve-Path -LiteralPath $Destination).Path

    if ([string]::IsNullOrWhiteSpace($Template)) {
        if ($interactive) {
            Write-Host 'Available templates:'
            for ($index = 0; $index -lt $availableTemplates.Count; $index++) {
                Write-Host "[$($index + 1)] $($availableTemplates[$index])"
            }
            $choice = Read-Host 'Template number or name (default: 1)'
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $Template = $availableTemplates[0]
            } elseif ($choice -match '^[0-9]+$' -and [int]$choice -ge 1 -and [int]$choice -le $availableTemplates.Count) {
                $Template = $availableTemplates[[int]$choice - 1]
            } else {
                $Template = $choice.Trim()
            }
        } else {
            $Template = $availableTemplates[0]
        }
    }
    $Template = $Template.Trim()
    if ($availableTemplates -notcontains $Template) {
        throw "Unknown template '$Template'. Choose one of: $($availableTemplates -join ', ')"
    }

    $templateRoot = (Resolve-Path -LiteralPath (Join-Path $templatesRoot $Template)).Path
    $templatePrefix = $templatesRoot.TrimEnd('\') + '\'
    if (-not $templateRoot.StartsWith($templatePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Template path escaped the repository scaffold directory.'
    }

    $newProjectDir = Join-Path $destinationRoot $Name
    if (Test-Path -LiteralPath $newProjectDir) {
        throw "Destination directory already exists: $newProjectDir"
    }

    if ($PSCmdlet.ShouldProcess($newProjectDir, "Create cscui project from '$Template'")) {
        New-Item -ItemType Directory -LiteralPath $newProjectDir | Out-Null
        Get-ChildItem -LiteralPath $templateRoot -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $newProjectDir -Recurse -Force
        }

        Replace-Token -Path (Join-Path $newProjectDir 'CMakeLists.txt') -Token '__PROJECT_NAME__' -Value $Name
        Replace-Token -Path (Join-Path $newProjectDir 'main.cpp') -Token '__PROJECT_NAME__' -Value $Name
        Replace-Token -Path (Join-Path $newProjectDir 'Main.qml') -Token '{{PROJECT_NAME}}' -Value $Name
        Replace-Token -Path (Join-Path $newProjectDir 'package.bat') -Token '{{PROJECT_NAME}}' -Value $Name

        Copy-DirectoryContents -Source (Join-Path $repoRoot 'components') -DestinationPath (Join-Path $newProjectDir 'components')
        Copy-DirectoryContents -Source (Join-Path $repoRoot 'fonts') -DestinationPath (Join-Path $newProjectDir 'fonts')
        Copy-Item -LiteralPath (Join-Path $repoRoot 'src.qrc') -Destination (Join-Path $newProjectDir 'src.qrc')

        Write-Host "Project generated: $newProjectDir"
        Write-Host "Configure: cmake -S `"$newProjectDir`" -B `"$newProjectDir\build`""
        Write-Host "Build:     cmake --build `"$newProjectDir\build`""
        Write-Host "Template:  $Template"
    }
} catch {
    Write-Error $_
    exit 1
}
