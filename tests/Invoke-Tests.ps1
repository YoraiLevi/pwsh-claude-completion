#Requires -Version 5.1
<#
.SYNOPSIS
    Installs (if needed) and runs Pester 5 against ./tests.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

$pester = Get-Module Pester -ListAvailable |
    Where-Object { $_.Version -ge [version]'5.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module Pester -MinimumVersion 5.5.0 -MaximumVersion 5.99.99 -Force -SkipPublisherCheck -Scope CurrentUser
}

if (-not (Get-Module PSScriptAnalyzer -ListAvailable)) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module PSScriptAnalyzer -MinimumVersion 1.21.0 -Force -SkipPublisherCheck -Scope CurrentUser
}

Import-Module Pester -MinimumVersion 5.0.0 -Force

$config = New-PesterConfiguration
$config.Run.Path = Join-Path $repoRoot 'tests'
$config.Run.Exit = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path $repoRoot 'testResults.xml'
$config.Output.Verbosity = 'Detailed'

. (Join-Path $PSScriptRoot 'Helpers.ps1')
$axes = Get-ClaudeHelpAxes
$n = $axes.Count
$total = [int][Math]::Pow(2, $n)
Write-Host "Combinatorial axes (n=$n): $($axes -join ', ')"
Write-Host "Expecting 2^$n = $total generated help shapes, each exercised by parser + completer tests."

Invoke-Pester -Configuration $config
