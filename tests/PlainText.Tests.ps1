#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $moduleRoot 'ClaudeCompletion.psd1') -Force
}

Describe 'ConvertTo-ClaudePlainText' {
    It 'turns a real Unicode en-dash into a hyphen' {
        $raw = "Auto-compact window size (auto, or 100k$([char]0x2013)1M tokens)"
        ConvertTo-ClaudePlainText -Text $raw | Should -Be 'Auto-compact window size (auto, or 100k-1M tokens)'
    }

    It 'repairs CP437 mojibake of an en-dash (Gamma Cedilla o)' {
        $raw = 'Auto-compact window size (auto, or 100k' + [char]0x0393 + [char]0x00C7 + [char]0x00F4 + '1M tokens)'
        ConvertTo-ClaudePlainText -Text $raw | Should -Be 'Auto-compact window size (auto, or 100k-1M tokens)'
    }

    It 'turns curly quotes into ASCII quotes' {
        $raw = "e.g., $([char]0x201C)api,hooks$([char]0x201D) or $([char]0x2018)!1p,!file$([char]0x2019)"
        ConvertTo-ClaudePlainText -Text $raw | Should -Be 'e.g., "api,hooks" or ''!1p,!file'''
    }

    It 'parser descriptions do not keep the odd glyphs' {
        $help = @"
Options:
  --autocompact <auto|tokens>   Auto-compact window size (auto, or 100k$([char]0x2013)1M tokens)
  -d, --debug [filter]          Enable debug mode with optional category filtering (e.g., $([char]0x201C)api,hooks$([char]0x201D) or $([char]0x201C)!1p,!file$([char]0x201D))
"@
        $spec = ConvertFrom-ClaudeHelpText -Text $help
        $spec.Options['--autocompact'].Description | Should -Be 'Auto-compact window size (auto, or 100k-1M tokens)'
        $spec.Options['--autocompact'].Description | Should -Not -Match ([char]0x2013)
        $spec.Options['--autocompact'].Description | Should -Not -Match ([char]0x0393)
        $spec.Options['--debug'].Description | Should -Match 'e.g., "api,hooks"'
        $spec.Options['--debug'].Description | Should -Not -Match ([char]0x201C)
    }
}

Describe 'Get-ClaudeNativeCommand' {
    It 'returns an Application, never a function or alias named claude' {
        $cmd = Get-ClaudeNativeCommand
        if (-not $cmd) {
            Set-ItResult -Skipped -Because 'no claude Application on PATH'
            return
        }
        $cmd.CommandType | Should -Be ([System.Management.Automation.CommandTypes]::Application)
        $cmd.Name | Should -Not -Be 'Invoke-Claude'
    }
}

Describe 'live claude.exe help (skipped when the CLI is absent)' {
    It 'root --help tooltips are ASCII-safe after parse' {
        $native = Get-ClaudeNativeCommand
        if (-not $native) {
            Set-ItResult -Skipped -Because 'claude.exe not on PATH'
            return
        }
        Reset-ClaudeHelpCache
        Set-ClaudeHelpProvider -Provider $null
        $spec = Get-ClaudeHelpSpec -Path @()
        $spec.Options.ContainsKey('--autocompact') | Should -BeTrue
        $desc = $spec.Options['--autocompact'].Description
        $desc | Should -Match '100k-1M'
        $desc | Should -Not -Match ([char]0x0393)
        $desc | Should -Not -Match ([char]0x2013)
        $desc | Should -Not -Match ([char]0x00E2)
    }

    It 'mcp empty Tab offers add, not Commander help or -h/--help' {
        $native = Get-ClaudeNativeCommand
        if (-not $native) {
            Set-ItResult -Skipped -Because 'claude.exe not on PATH'
            return
        }
        Reset-ClaudeHelpCache
        Set-ClaudeHelpProvider -Provider $null
        $texts = @(Complete-ClaudeNativeArgument -wordToComplete '' -Tokens @('mcp') | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain 'add'
        $texts | Should -Not -Contain 'help'
        $texts | Should -Not -Contain '--help'
        $texts | Should -Not -Contain '-h'
    }
}
