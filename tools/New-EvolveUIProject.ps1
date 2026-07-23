<#
Compatibility entry point for automation that still uses the former name.
Use New-CscuiProject.ps1 for new projects.
#>
[CmdletBinding()]
param(
    [string]$Name,
    [string]$Destination,
    [string]$Template,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Write-Warning 'New-EvolveUIProject.ps1 is deprecated; use New-CscuiProject.ps1 instead.'

$canonicalScript = Join-Path $PSScriptRoot 'New-CscuiProject.ps1'
$forward = @{}
if ($PSBoundParameters.ContainsKey('Name')) { $forward['Name'] = $Name }
if ($PSBoundParameters.ContainsKey('Destination')) { $forward['Destination'] = $Destination }
if ($PSBoundParameters.ContainsKey('Template')) { $forward['Template'] = $Template }
if ($NonInteractive) { $forward['NonInteractive'] = $true }

& $canonicalScript @forward
$exitCode = if ($?) { 0 } elseif ($LASTEXITCODE) { $LASTEXITCODE } else { 1 }
exit $exitCode
