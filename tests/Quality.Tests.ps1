#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ManifestPath = Join-Path $script:ModuleRoot 'ClaudeCompletion.psd1'
}

Describe 'module manifest' {
    It 'Test-ModuleManifest succeeds' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'manifest has Gallery-required Author, Description, and ModuleVersion' {
        $m = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        $m.Author | Should -Not -BeNullOrEmpty
        $m.Description | Should -Not -BeNullOrEmpty
        $m.Version | Should -BeGreaterThan ([version]'0.0.0')
    }
}

Describe 'PSScriptAnalyzer' {
    BeforeAll {
        $script:Analyzer = Get-Module PSScriptAnalyzer -ListAvailable |
            Sort-Object Version -Descending |
            Select-Object -First 1
        if ($script:Analyzer) {
            Import-Module PSScriptAnalyzer -Force
        }
    }

    It 'reports no Error or Warning on the module' {
        if (-not $script:Analyzer) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }
        $settings = Join-Path $script:ModuleRoot 'PSScriptAnalyzerSettings.psd1'
        $params = @{
            Path     = Join-Path $script:ModuleRoot 'ClaudeCompletion.psm1'
            Severity = @('Error', 'Warning')
        }
        if (Test-Path $settings) { $params.Settings = $settings }
        $issues = @(Invoke-ScriptAnalyzer @params)
        $issues | Should -BeNullOrEmpty -Because (
            ($issues | ForEach-Object { '{0}:{1} {2}' -f $_.Line, $_.RuleName, $_.Message }) -join '; '
        )
    }
}
