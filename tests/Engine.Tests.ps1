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

    It 'CompleteInput after claude[space] offers mcp, not flags' {
        $input = 'claude '
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)
        $texts = @($result.CompletionMatches | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain 'mcp'
        $texts | Should -Not -Contain '--model'
        $texts | Should -Not -Contain '--verbose'
    }

    It 'CompleteInput after claude --v offers --verbose, not mcp' {
        $input = 'claude --v'
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)
        $texts = @($result.CompletionMatches | ForEach-Object { $_.CompletionText })
        $texts | Should -Contain '--verbose'
        $texts | Should -Not -Contain 'mcp'
    }
}
