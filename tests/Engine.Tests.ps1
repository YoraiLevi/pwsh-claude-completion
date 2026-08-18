#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $moduleRoot 'ClaudeCompletion.psd1') -Force
    Set-ClaudeHelpProvider -Provider {
        @"
Options:
  --model <model>   Model for the session (choices: "fable", "opus")
  --verbose         Verbose
Commands:
  mcp               Configure MCP
"@
    }
    Reset-ClaudeHelpCache
    Register-ClaudeArgumentCompleter
}

AfterAll {
    Reset-ClaudeHelpCache
    Set-ClaudeHelpProvider -Provider $null
}

Describe 'engine-level native completion' {
    It 'CommandCompletion.CompleteInput offers --model for claude --mo' {
        $input = 'claude --mo'
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)
        @($result.CompletionMatches | ForEach-Object { $_.CompletionText }) | Should -Contain '--model'
    }

    It 'TabExpansion2 offers --model for claude --mo' {
        $input = 'claude --mo'
        $result = TabExpansion2 -inputScript $input -cursorColumn $input.Length
        @($result.CompletionMatches | ForEach-Object { $_.CompletionText }) | Should -Contain '--model'
    }

    It 'CompleteInput offers mcp for claude m' {
        $input = 'claude m'
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)
        @($result.CompletionMatches | ForEach-Object { $_.CompletionText }) | Should -Contain 'mcp'
    }
}
